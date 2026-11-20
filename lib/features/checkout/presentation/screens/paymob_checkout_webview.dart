import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';

/// Card fields already collected in-app, injected into Paymob's iframe.
class PaymobCardAutofill {
  const PaymobCardAutofill({
    this.number,
    this.holderName,
    this.expiryMonth,
    this.expiryYear,
    this.cvv,
  });

  final String? number;
  final String? holderName;
  final String? expiryMonth;
  final String? expiryYear;
  final String? cvv;

  bool get hasAnything =>
      (number != null && number!.isNotEmpty) ||
      (holderName != null && holderName!.isNotEmpty) ||
      (expiryMonth != null && expiryMonth!.isNotEmpty) ||
      (expiryYear != null && expiryYear!.isNotEmpty) ||
      (cvv != null && cvv!.isNotEmpty);
}

/// In-app Paymob iframe so the customer can finish 3DS without retyping
/// the card when autofill data is available.
class PaymobCheckoutWebView extends StatefulWidget {
  const PaymobCheckoutWebView({
    super.key,
    required this.paymentUrl,
    this.autofill,
  });

  final Uri paymentUrl;
  final PaymobCardAutofill? autofill;

  @override
  State<PaymobCheckoutWebView> createState() => _PaymobCheckoutWebViewState();
}

class _PaymobCheckoutWebViewState extends State<PaymobCheckoutWebView> {
  late final WebViewController _controller;
  var _loading = true;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_handleReturnUrl(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (url) {
            if (_handleReturnUrl(url)) return;
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) async {
            if (_handleReturnUrl(url)) return;
            await _injectAutofill();
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            final url = error.url;
            if (url != null && _handleReturnUrl(url)) return;
          },
        ),
      )
      ..loadRequest(widget.paymentUrl);
  }

  /// Intercepts Paymob / deep-link return URLs so the WebView never loads
  /// `io.supabase.safeermarket://…` (which would show ERR_UNKNOWN_URL_SCHEME).
  bool _handleReturnUrl(String rawUrl) {
    if (_finished) return true;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return false;

    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final full = rawUrl.toLowerCase();
    final isCustomScheme = scheme != 'http' &&
        scheme != 'https' &&
        scheme != 'about' &&
        scheme != 'data' &&
        scheme.isNotEmpty;
    final isPaymentResult = scheme == 'io.supabase.safeermarket' ||
        host == 'payment-result' ||
        full.contains('payment-result') ||
        full.contains('accept.paymobsolutions.com/api/acceptance/post_pay') ||
        full.contains('accept.paymob.com/api/acceptance/post_pay');

    if (!isCustomScheme && !isPaymentResult) return false;

    final params = uri.queryParameters;
    final successRaw =
        (params['success'] ?? params['status'] ?? '').toLowerCase();
    final success = successRaw == 'true' ||
        successRaw == 'success' ||
        successRaw == '1' ||
        successRaw == 'approved';
    _finish(success);
    return true;
  }

  void _finish(bool success) {
    if (_finished || !mounted) return;
    _finished = true;
    Navigator.of(context).pop(success);
  }

  Future<void> _injectAutofill() async {
    final data = widget.autofill;
    if (data == null || !data.hasAnything) return;

    final payload = jsonEncode({
      'number': (data.number ?? '').replaceAll(RegExp(r'\D'), ''),
      'name': data.holderName ?? '',
      'month': data.expiryMonth ?? '',
      'year': data.expiryYear ?? '',
      'cvv': data.cvv ?? '',
    });

    // Poll + character-by-character typing so Paymob input masks accept PAN.
    final script = '''
(function() {
  if (window.__safeerAutofillStarted) return;
  window.__safeerAutofillStarted = true;
  var data = $payload;
  var setter = Object.getOwnPropertyDescriptor(
    window.HTMLInputElement.prototype, 'value'
  ).set;
  var selectSetter = Object.getOwnPropertyDescriptor(
    window.HTMLSelectElement.prototype, 'value'
  ).set;

  function fireKey(el, type, key) {
    var code = key.length === 1 ? key.charCodeAt(0) : 0;
    el.dispatchEvent(new KeyboardEvent(type, {
      bubbles: true, cancelable: true, key: key, code: key.length === 1 ? ('Digit' + key) : key,
      keyCode: code, which: code, charCode: type === 'keypress' ? code : 0
    }));
  }

  function fire(el) {
    el.dispatchEvent(new Event('input', { bubbles: true }));
    el.dispatchEvent(new Event('change', { bubbles: true }));
    fireKey(el, 'keyup', '0');
    el.dispatchEvent(new Event('blur', { bubbles: true }));
  }

  function typeChars(el, raw) {
    if (!el || !raw) return false;
    el.focus();
    if (setter) setter.call(el, ''); else el.value = '';
    fire(el);
    el.focus();
    var formatted = '';
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 4 === 0) {
        // Some masks insert spaces themselves; also try spaced form.
      }
      var ch = raw.charAt(i);
      fireKey(el, 'keydown', ch);
      fireKey(el, 'keypress', ch);
      formatted += ch;
      var spaced = raw.replace(/(\\d{4})(?=\\d)/g, '\$1 ').trim();
      var next = (el.placeholder || '').toLowerCase().indexOf('xxxx') !== -1
        ? spaced.substring(0, Math.floor(i / 4) * 5 + (i % 4) + 1)
        : formatted;
      if (setter) setter.call(el, next); else el.value = next;
      try {
        el.dispatchEvent(new InputEvent('input', {
          bubbles: true, cancelable: true, inputType: 'insertText', data: ch
        }));
      } catch (e) {
        el.dispatchEvent(new Event('input', { bubbles: true }));
      }
      try {
        el.dispatchEvent(new Event('textInput', { bubbles: true, data: ch }));
      } catch (e) {}
      fireKey(el, 'keyup', ch);
    }
    // Final pass: set full raw + spaced variants.
    var spacedFull = raw.replace(/(\\d{4})(?=\\d)/g, '\$1 ').trim();
    if (setter) setter.call(el, spacedFull); else el.value = spacedFull;
    fire(el);
    if ((el.value || '').replace(/\\D/g, '').length < raw.length) {
      if (setter) setter.call(el, raw); else el.value = raw;
      fire(el);
    }
    return (el.value || '').replace(/\\D/g, '').length >= Math.min(13, raw.length);
  }

  function setValue(el, value) {
    if (!el || value === null || value === undefined || value === '') return false;
    try {
      el.focus();
      if (el.tagName === 'SELECT' && selectSetter) {
        selectSetter.call(el, value);
        fire(el);
        return true;
      }
      if (setter) setter.call(el, value); else el.value = value;
      try { var tracker = el._valueTracker; if (tracker) tracker.setValue(''); } catch (e) {}
      fire(el);
      return el.value === value || el.tagName === 'SELECT';
    } catch (e) {
      try { el.value = value; fire(el); return true; } catch (_) { return false; }
    }
  }

  function matches(el, patterns) {
    var blob = [
      el.name || '', el.id || '', el.placeholder || '',
      el.getAttribute('autocomplete') || '',
      el.getAttribute('aria-label') || '',
      el.className || ''
    ].join(' ').toLowerCase();
    return patterns.some(function(p) { return blob.indexOf(p) !== -1; });
  }

  function pick(doc, patterns) {
    var inputs = Array.prototype.slice.call(doc.querySelectorAll('input, select'));
    for (var i = 0; i < inputs.length; i++) {
      var el = inputs[i];
      var type = (el.type || '').toLowerCase();
      if (type === 'hidden' || type === 'submit' || type === 'button' || type === 'checkbox') continue;
      if (matches(el, patterns)) return el;
    }
    return null;
  }

  function findCardNumber(doc) {
    return document.getElementById('cardNumber')
      || pick(doc, ['card number', 'cardnumber', 'card_number', 'card-number', 'cc-number', 'pan', 'رقم البطاقة'])
      || pick(doc, ['number'])
      || (function() {
        var form = doc.querySelector('form');
        var first = form && form.querySelector('input[type="tel"], input[type="text"], input:not([type])');
        return first || null;
      })();
  }

  function fill(doc) {
    if (!doc) return false;
    var numberEl = findCardNumber(doc);
    var numberOk = false;
    if (data.number && numberEl) {
      numberOk = typeChars(numberEl, data.number);
      if (!numberOk) numberOk = setValue(numberEl, data.number);
    }
    setValue(pick(doc, [
      'card holder', 'cardholder', 'card_holder', 'holder', 'cc-name',
      'name on card', 'اسم حامل'
    ]), data.name);
    var expiryCombined = (data.month && data.year) ? (data.month + '/' + data.year) : '';
    var expiryEl = pick(doc, [
      'expiry', 'expiration', 'cc-exp', 'exp-date', 'تاريخ الانتهاء', 'mm/yy', 'mm / yy'
    ]);
    if (expiryEl) setValue(expiryEl, expiryCombined || data.month);
    else {
      setValue(pick(doc, ['expiry month', 'expmonth', 'month', 'cc-exp-month']), data.month);
      setValue(pick(doc, ['expiry year', 'expyear', 'year', 'cc-exp-year']), data.year);
    }
    setValue(pick(doc, ['cvv', 'cvc', 'cvn', 'security code', 'cc-csc', 'رمز']), data.cvv);
    return numberOk || !!numberEl;
  }

  function walk(root) {
    var found = fill(root);
    var frames = root.querySelectorAll ? root.querySelectorAll('iframe') : [];
    Array.prototype.forEach.call(frames, function(frame) {
      try {
        var child = frame.contentDocument || frame.contentWindow.document;
        if (walk(child)) found = true;
      } catch (e) {}
    });
    return found;
  }

  var tries = 0;
  var maxTries = Math.ceil(5000 / 300);
  var timer = setInterval(function() {
    tries++;
    var done = false;
    try { done = walk(document); } catch (e) {}
    if (done || tries >= maxTries) {
      clearInterval(timer);
      window.__safeerAutofillStarted = false;
    }
  }, 300);
  try { walk(document); } catch (e) {}
})();
''';

    try {
      await _controller.runJavaScript(script);
    } catch (_) {
      // Autofill is best-effort; user can still type / complete 3DS.
    }
  }

  Future<void> _copyCardNumber() async {
    final digits =
        (widget.autofill?.number ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || !mounted) return;
    await Clipboard.setData(ClipboardData(text: digits));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.paymentCardNumberCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canCopyCard = (widget.autofill?.number ?? '')
            .replaceAll(RegExp(r'\D'), '')
            .length >=
        13;
    return Scaffold(
      backgroundColor: context.palette.surface,
      appBar: AppBar(
        title: Text(l10n.paymentCardTitle),
        leading: IconButton(
          tooltip: l10n.close,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          if (canCopyCard)
            TextButton.icon(
              onPressed: _copyCardNumber,
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l10n.paymentCopyCardNumber),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
