// lib/screens/tab_admin.dart
import 'package:flutter/material.dart';
import '../services/api_client.dart';

class TabAdmin extends StatefulWidget {
  final ApiClient api;
  const TabAdmin({super.key, required this.api});

  @override
  State<TabAdmin> createState() => _TabAdminState();
}

class _TabAdminState extends State<TabAdmin> {
  int _subIdx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _CitiesPanel(api: widget.api),
      _RoutesPanel(api: widget.api),
      _StopsPanel(api: widget.api),
      _RouteStopsPanel(api: widget.api),
    ];
    return Column(
      children: [
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Cities')),
            ButtonSegment(value: 1, label: Text('Routes')),
            ButtonSegment(value: 2, label: Text('Stops')),
            ButtonSegment(value: 3, label: Text('Route-Stops')),
          ],
          selected: {_subIdx},
          onSelectionChanged: (s) => setState(() => _subIdx = s.first),
        ),
        const Divider(height: 16),
        Expanded(child: pages[_subIdx]),
      ],
    );
  }
}

// -------------------- Cities --------------------
class _CitiesPanel extends StatefulWidget {
  final ApiClient api;
  const _CitiesPanel({required this.api});
  @override
  State<_CitiesPanel> createState() => _CitiesPanelState();
}
class _CitiesPanelState extends State<_CitiesPanel> {
  final _nameCtrl = TextEditingController();
  bool _busy = false;
  List<dynamic> _items = [];
  String? _err;

  Future<void> _load() async {
    setState(() { _busy = true; _err = null; });
    try {
      _items = await widget.api.adminListCities();
    } catch (e) {
      _err = e.toString();
    } finally {
      setState(() { _busy = false; });
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() { _busy = true; _err = null; });
    try {
      await widget.api.adminUpsertCity(name);
      _nameCtrl.clear();
      await _load();
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'City Name'))),
            const SizedBox(width: 8),
            FilledButton(onPressed: _busy ? null : _save, child: const Text('Save')),
            const SizedBox(width: 8),
            IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          ]),
          if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 8),
          Expanded(
            child: _busy ? const Center(child: CircularProgressIndicator()) :
            ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final it = _items[i] as Map<String, dynamic>;
                return ListTile(
                  title: Text(it['name'] ?? ''),
                  subtitle: Text('id: ${it['id']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- Routes --------------------
class _RoutesPanel extends StatefulWidget {
  final ApiClient api;
  const _RoutesPanel({required this.api});
  @override
  State<_RoutesPanel> createState() => _RoutesPanelState();
}
class _RoutesPanelState extends State<_RoutesPanel> {
  bool _busy = false;
  String? _err;

  final _code = TextEditingController();
  final _distance = TextEditingController(text: '0');
  int? _fromCityId;
  int? _toCityId;

  List<dynamic> _cities = [];
  List<dynamic> _routes = [];

  Future<void> _load() async {
    setState(() { _busy = true; _err = null; });
    try {
      _cities = await widget.api.adminListCities();
      _routes = await widget.api.adminListRoutes();
    } catch (e) {
      _err = e.toString();
    } finally {
      setState(() { _busy = false; });
    }
  }

  Future<void> _create() async {
    if (_code.text.trim().isEmpty || _fromCityId == null || _toCityId == null) return;
    final dist = num.tryParse(_distance.text.trim()) ?? 0;
    setState(() { _busy = true; _err = null; });
    try {
      await widget.api.adminCreateRoute(
        code: _code.text.trim(),
        fromCityId: _fromCityId!,
        toCityId: _toCityId!,
        distanceKm: dist,
      );
      _code.clear();
      _distance.text = '0';
      await _load();
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 12, runSpacing: 8, children: [
            SizedBox(
              width: 160,
              child: TextField(controller: _code, decoration: const InputDecoration(labelText: 'Route Code')),
            ),
            _CityDropdown(
              cities: _cities,
              label: 'From City',
              onChanged: (id) => setState(() => _fromCityId = id),
              value: _fromCityId,
            ),
            _CityDropdown(
              cities: _cities,
              label: 'To City',
              onChanged: (id) => setState(() => _toCityId = id),
              value: _toCityId,
            ),
            SizedBox(
              width: 140,
              child: TextField(controller: _distance, decoration: const InputDecoration(labelText: 'Distance (km)'), keyboardType: TextInputType.number),
            ),
            FilledButton(onPressed: _busy ? null : _create, child: const Text('Create')),
            IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          ]),
          if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 8),
          Expanded(
            child: _busy ? const Center(child: CircularProgressIndicator()) :
            ListView.separated(
              itemCount: _routes.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = _routes[i] as Map<String, dynamic>;
                return ListTile(
                  title: Text(r['code'] ?? ''),
                  subtitle: Text('id: ${r['id']} | from: ${r['from_city_id']} → to: ${r['to_city_id']} | ${r['distance_km']} km'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- Stops --------------------
class _StopsPanel extends StatefulWidget {
  final ApiClient api;
  const _StopsPanel({required this.api});
  @override
  State<_StopsPanel> createState() => _StopsPanelState();
}
class _StopsPanelState extends State<_StopsPanel> {
  bool _busy = false;
  String? _err;

  final _name = TextEditingController();
  final _lat = TextEditingController(text: '19.0');
  final _lon = TextEditingController(text: '73.0');
  int? _cityId;

  List<dynamic> _cities = [];
  List<dynamic> _stops = [];

  Future<void> _load() async {
    setState(() { _busy = true; _err = null; });
    try {
      _cities = await widget.api.adminListCities();
      _stops = await widget.api.adminListStops();
    } catch (e) {
      _err = e.toString();
    } finally {
      setState(() { _busy = false; });
    }
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final lat = double.tryParse(_lat.text.trim());
    final lon = double.tryParse(_lon.text.trim());
    if (name.isEmpty || _cityId == null || lat == null || lon == null) return;
    setState(() { _busy = true; _err = null; });
    try {
      await widget.api.adminCreateStop(name: name, lat: lat, lon: lon, cityId: _cityId!);
      _name.clear(); _lat.text = '19.0'; _lon.text = '73.0';
      await _load();
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 12, runSpacing: 8, children: [
            SizedBox(width: 220, child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'Stop Name'))),
            _CityDropdown(
              cities: _cities,
              label: 'City',
              onChanged: (id) => setState(() => _cityId = id),
              value: _cityId,
            ),
            SizedBox(width: 140, child: TextField(controller: _lat, decoration: const InputDecoration(labelText: 'Lat'), keyboardType: TextInputType.number)),
            SizedBox(width: 140, child: TextField(controller: _lon, decoration: const InputDecoration(labelText: 'Lon'), keyboardType: TextInputType.number)),
            FilledButton(onPressed: _busy ? null : _create, child: const Text('Create')),
            IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          ]),
          if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 8),
          Expanded(
            child: _busy ? const Center(child: CircularProgressIndicator()) :
            ListView.separated(
              itemCount: _stops.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = _stops[i] as Map<String, dynamic>;
                return ListTile(
                  title: Text(s['name'] ?? ''),
                  subtitle: Text('id: ${s['id']} | city: ${s['city_id']} | (${s['lat']}, ${s['lon']})'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- Route-Stops mapping --------------------
class _RouteStopsPanel extends StatefulWidget {
  final ApiClient api;
  const _RouteStopsPanel({required this.api});
  @override
  State<_RouteStopsPanel> createState() => _RouteStopsPanelState();
}
class _RouteStopsPanelState extends State<_RouteStopsPanel> {
  bool _busy = false;
  String? _err;

  List<dynamic> _routes = [];
  List<dynamic> _stops = [];

  int? _routeId;
  int? _stopId;
  final _rank = TextEditingController(text: '1');

  Future<void> _load() async {
    setState(() { _busy = true; _err = null; });
    try {
      _routes = await widget.api.adminListRoutes();
      _stops  = await widget.api.adminListStops();
    } catch (e) {
      _err = e.toString();
    } finally {
      setState(() { _busy = false; });
    }
  }

  Future<void> _attach() async {
    if (_routeId == null || _stopId == null) return;
    final rank = int.tryParse(_rank.text.trim()) ?? 1;
    setState(() { _busy = true; _err = null; });
    try {
      await widget.api.adminAttachStopToRoute(routeId: _routeId!, stopId: _stopId!, rank: rank);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attached stop to route')));
    } catch (e) {
      setState(() { _err = e.toString(); });
    } finally {
      setState(() { _busy = false; });
    }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(spacing: 12, runSpacing: 8, children: [
            _IdDropdown(items: _routes, idKey: 'id', labelKey: 'code', label: 'Route', value: _routeId, onChanged: (v) => setState(() => _routeId = v)),
            _IdDropdown(items: _stops,  idKey: 'id', labelKey: 'name', label: 'Stop',  value: _stopId,  onChanged: (v) => setState(() => _stopId  = v)),
            SizedBox(width: 120, child: TextField(controller: _rank, decoration: const InputDecoration(labelText: 'Rank'), keyboardType: TextInputType.number)),
            FilledButton(onPressed: _busy ? null : _attach, child: const Text('Attach')),
            IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
          ]),
          if (_err != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_err!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 8),
          const Text('Tip: rank is the order of the stop along the route (1,2,3,...)'),
        ],
      ),
    );
  }
}

// -------------------- Small widgets --------------------
class _CityDropdown extends StatelessWidget {
  final List<dynamic> cities;
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  const _CityDropdown({required this.cities, required this.label, required this.onChanged, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      hint: Text(label),
      items: cities.map((c) {
        final m = c as Map<String, dynamic>;
        return DropdownMenuItem<int>(value: m['id'] as int, child: Text(m['name'] ?? ''));
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class _IdDropdown extends StatelessWidget {
  final List<dynamic> items;
  final String idKey;
  final String labelKey;
  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;
  const _IdDropdown({
    required this.items,
    required this.idKey,
    required this.labelKey,
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      hint: Text(label),
      items: items.map((m0) {
        final m = m0 as Map<String, dynamic>;
        return DropdownMenuItem<int>(value: m[idKey] as int, child: Text(m[labelKey]?.toString() ?? ''));
      }).toList(),
      onChanged: onChanged,
    );
  }
}
