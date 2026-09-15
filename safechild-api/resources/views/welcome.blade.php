<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('SafeChild - Ensemble pour leur sécurité') }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
</head>
<body class="bg-gray-50 font-sans">
    <!-- Navigation -->
    <nav class="bg-blue-900 text-white shadow-lg">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between h-16 items-center">
                <div class="flex items-center space-x-2">
                    <span class="text-2xl">🛡️</span>
                    <span class="text-xl font-bold tracking-wider">SAFE CHILD</span>
                </div>
                <div class="flex items-center space-x-6">
                    <a href="#map" class="hover:text-blue-200 transition">{{ __('Carte') }}</a>
                    <a href="#stats" class="hover:text-blue-200 transition">{{ __('Statistiques') }}</a>
                    <a href="{{ route('admin.login') }}" class="bg-white text-blue-900 px-4 py-2 rounded-lg font-bold hover:bg-blue-100 transition">{{ __('Espace Autorités') }}</a>
                    
                    <!-- Language Toggle Button -->
                    @if(app()->getLocale() == 'fr')
                        <a href="{{ route('lang.switch', 'en') }}" class="flex items-center space-x-1.5 bg-blue-800 hover:bg-blue-700 px-3 py-1.5 rounded-lg border border-blue-700 transition" title="Switch to English">
                            <span class="text-lg">🇬🇧</span>
                            <span class="font-bold text-xs">EN</span>
                        </a>
                    @else
                        <a href="{{ route('lang.switch', 'fr') }}" class="flex items-center space-x-1.5 bg-blue-800 hover:bg-blue-700 px-3 py-1.5 rounded-lg border border-blue-700 transition" title="Passer en Français">
                            <span class="text-lg">🇫🇷</span>
                            <span class="font-bold text-xs">FR</span>
                        </a>
                    @endif
                </div>
            </div>
        </div>
    </nav>

    <!-- Hero Section -->
    <header class="bg-blue-800 text-white py-20 px-4 text-center bg-gradient-to-b from-blue-900 to-blue-700">
        <h1 class="text-5xl font-extrabold mb-6">{{ __('Chaque seconde compte.') }}</h1>
        <p class="text-xl mb-10 max-w-2xl mx-auto opacity-90">{{ __("Plateforme communautaire et officielle pour la recherche immédiate d'enfants disparus. Ensemble, soyons vigilants.") }}</p>
        <div class="flex justify-center space-x-4">
            <a href="#map" class="bg-red-600 hover:bg-red-700 text-white px-8 py-4 rounded-xl font-bold text-lg shadow-xl transform hover:scale-105 transition">{{ __('VOIR LA CARTE EN DIRECT') }}</a>
        </div>
    </header>

    <!-- Public Map Section -->
    <section id="map" class="max-w-7xl mx-auto py-16 px-4">
        <div class="bg-white rounded-3xl shadow-2xl overflow-hidden border-4 border-white">
            <div class="p-6 bg-gray-50 border-b flex justify-between items-center">
                <h2 class="text-2xl font-bold text-blue-900">{{ __('Carte des Signalements Actifs') }}</h2>
                <div class="flex items-center space-x-4">
                    <span class="flex items-center text-sm"><span class="w-3 h-3 bg-red-500 rounded-full mr-2"></span> {{ __('Citoyen') }}</span>
                    <span class="flex items-center text-sm"><span class="w-3 h-3 bg-blue-500 rounded-full mr-2"></span> {{ __('Certifiée par Police') }}</span>
                </div>
            </div>
            <div id="public-map" class="h-[600px] w-full"></div>
        </div>
    </section>

    <!-- Stats Section -->
    <section id="stats" class="bg-white py-16">
        <div class="max-w-7xl mx-auto px-4 grid grid-cols-1 md:grid-cols-4 gap-8 text-center">
            <div class="p-8">
                <div class="text-4xl font-bold text-blue-900 mb-2">{{ \App\Models\MissingChild::where('status', 'missing')->count() }}</div>
                <div class="text-gray-500 uppercase tracking-widest text-sm">{{ __('Enfants recherchés') }}</div>
            </div>
            <div class="p-8">
                <div class="text-4xl font-bold text-green-600 mb-2">{{ \App\Models\MissingChild::where('status', 'found')->count() }}</div>
                <div class="text-gray-500 uppercase tracking-widest text-sm">{{ __('Enfants retrouvés') }}</div>
            </div>
            <div class="p-8">
                <div class="text-4xl font-bold text-blue-500 mb-2">{{ \App\Models\User::count() }}</div>
                <div class="text-gray-500 uppercase tracking-widest text-sm">{{ __('Citoyens vigilants') }}</div>
            </div>
            <div class="p-8">
                <div class="text-4xl font-bold text-red-500 mb-2">{{ \App\Models\MissingChild::where('is_verified', true)->count() }}</div>
                <div class="text-gray-500 uppercase tracking-widest text-sm">{{ __('Alertes certifiées') }}</div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <footer class="bg-gray-900 text-gray-400 py-12 px-4 text-center">
        <p class="mb-4">{{ __('© 2026 SafeChild. Protégeons nos enfants, ensemble.') }}</p>
        <p class="text-sm">{{ __("En cas d'urgence immédiate, contactez le 17 (Police) ou le 112.") }}</p>
    </footer>

    <!-- Leaflet Script -->
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            var map = L.map('public-map').setView([0, 0], 2);
            
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors'
            }).addTo(map);

            @php
                $children = \App\Models\MissingChild::where('status', 'missing')->get();
            @endphp

            var markers = [
                @foreach($children as $child)
                {
                    lat: {{ $child->disappearance_lat }},
                    lng: {{ $child->disappearance_lng }},
                    name: "{{ $child->name }}",
                    age: "{{ $child->age }} {{ __('ans') }}",
                    verified: {{ $child->is_verified ? 'true' : 'false' }}
                },
                @endforeach
            ];

            if (markers.length > 0) {
                var group = new L.featureGroup();
                markers.forEach(function(m) {
                    var color = m.verified ? 'blue' : 'red';
                    // Custom icon logic for verification
                    var icon = L.divIcon({
                        className: 'custom-div-icon',
                        html: "<div style='background-color:"+color+"; width:12px; height:12px; border-radius:50%; border:2px solid white; box-shadow:0 0 5px rgba(0,0,0,0.5);'></div>",
                        iconSize: [12, 12],
                        iconAnchor: [6, 6]
                    });

                    L.marker([m.lat, m.lng], {icon: icon})
                        .bindPopup("<b>" + (m.verified ? '✅ ' : '') + m.name + "</b><br>" + m.age)
                        .addTo(map);
                    group.addLayer(L.marker([m.lat, m.lng]));
                });
                map.fitBounds(group.getBounds().pad(0.5));
            }
        });
    </script>
</body>
</html>
