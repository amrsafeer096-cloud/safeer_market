import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/services/place_search_service.dart';
import '../providers/addresses_providers.dart';

/// «ابحث عن منطقة أو شارع...»: suggestions as the user types; picking one
/// hands its coordinates to [onPicked].
class PlaceSearchBar extends ConsumerStatefulWidget {
  const PlaceSearchBar({super.key, required this.near, required this.onPicked});

  /// How long typing pauses before a search runs.
  static const debounce = Duration(milliseconds: 350);

  /// Where the map is, so nearby places come first.
  final LatLng near;
  final ValueChanged<LatLng> onPicked;

  @override
  ConsumerState<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends ConsumerState<PlaceSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  /// Bumped per search, so a slow answer to an older query is dropped.
  int _request = 0;
  bool _loading = false;
  List<PlaceSuggestion>? _results;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().isEmpty) {
      _request++;
      setState(() {
        _loading = false;
        _results = null;
        _error = null;
      });
      return;
    }
    _debounce = Timer(PlaceSearchBar.debounce, () => _search(text));
  }

  Future<void> _search(String text) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(placeSearchServiceProvider)
          .suggest(text, near: widget.near);
      if (!mounted || request != _request) return;
      // Pasted Maps URL / raw coordinates → jump the pin immediately.
      if (results.length == 1 &&
          results.first.point != null &&
          results.first.subtitle == 'إحداثيات') {
        await _pick(results.first);
        return;
      }
      setState(() {
        _loading = false;
        _results = results;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _loading = false;
        _results = null;
        _error = l10n == null
            ? '$error'
            : l10n.mapSearchFailed('$error');
      });
    }
  }

  Future<void> _pick(PlaceSuggestion suggestion) async {
    _focus.unfocus();
    final request = ++_request;
    setState(() => _loading = true);
    try {
      final point =
          await ref.read(placeSearchServiceProvider).locate(suggestion);
      if (!mounted || request != _request) return;
      _controller.text = suggestion.title;
      setState(() {
        _loading = false;
        _results = null;
      });
      widget.onPicked(point);
    } catch (error) {
      if (!mounted || request != _request) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _loading = false;
        _error =
            l10n == null ? '$error' : l10n.mapSearchFailed('$error');
      });
    }
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final results = _results;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: palette.card,
          elevation: 3,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(14),
          child: TextField(
            key: const Key('map-search-field'),
            controller: _controller,
            focusNode: _focus,
            onChanged: _onChanged,
            onSubmitted: (text) {
              _debounce?.cancel();
              if (text.trim().isNotEmpty) _search(text);
            },
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.mapSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.mapSearchClear,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _clear,
                        ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (_error case final error?)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              color: palette.card,
              elevation: 3,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(error, style: TextStyle(color: palette.muted)),
              ),
            ),
          )
        else if (results != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Material(
              color: palette.card,
              elevation: 3,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(l10n.mapSearchNoResults,
                          style: TextStyle(color: palette.muted)),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = results[index];
                          final subtitle = place.subtitle;
                          return ListTile(
                            key: Key('map-search-result-$index'),
                            dense: true,
                            leading: Icon(Icons.place_outlined,
                                color: palette.accent),
                            title: Text(place.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: subtitle == null
                                ? null
                                : Text(subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                            onTap: () => _pick(place),
                          );
                        },
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}
