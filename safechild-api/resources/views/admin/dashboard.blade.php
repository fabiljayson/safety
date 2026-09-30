@extends('layouts.admin')

@section('title', __('Tableau de bord des autorités'))

@section('content')
<div class="space-y-6">
    <!-- Actions Bar -->
    <div class="flex justify-between items-center bg-white p-4 shadow rounded-lg">
        <h2 class="text-lg font-semibold text-gray-700">{{ __('Actions Rapides') }}</h2>
        <a href="{{ route('admin.export.pdf') }}" class="inline-flex items-center rounded-md bg-blue-900 px-4 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-800">
            📥 {{ __('Télécharger le rapport PDF') }}
        </a>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 gap-5 sm:grid-cols-4">
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6 border-l-4 border-blue-500">
            <dt class="truncate text-sm font-medium text-gray-500">{{ __('En attente de validation') }}</dt>
            <dd class="mt-1 text-3xl font-semibold tracking-tight text-blue-600">{{ $stats['pending_verification'] }}</dd>
        </div>
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6 border-l-4 border-indigo-500">
            <dt class="truncate text-sm font-medium text-gray-500">{{ __('Enfants disparus') }}</dt>
            <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">{{ $stats['total_children'] }}</dd>
        </div>
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6 border-l-4 border-purple-500">
            <dt class="truncate text-sm font-medium text-gray-500">{{ __('Adultes disparus') }}</dt>
            <dd class="mt-1 text-3xl font-semibold tracking-tight text-gray-900">{{ $stats['total_adults'] }}</dd>
        </div>
        <div class="overflow-hidden rounded-lg bg-white px-4 py-5 shadow sm:p-6 border-l-4 border-red-500">
            <dt class="truncate text-sm font-medium text-gray-500">{{ __('Personnes recherchées') }}</dt>
            <dd class="mt-1 text-3xl font-semibold tracking-tight text-red-600">{{ $stats['total_wanted'] }}</dd>
        </div>
    </div>

    <!-- Filter Bar -->
    <div class="bg-white p-4 shadow rounded-lg flex flex-wrap items-center justify-between gap-4">
        <div class="flex flex-wrap items-center gap-2">
            <span class="text-sm font-medium text-gray-700">{{ __('Catégories:') }}</span>
            <a href="{{ route('admin.dashboard', array_merge(request()->query(), ['type' => 'all'])) }}" class="px-3 py-1 text-xs rounded-full {{ !request('type') || request('type') === 'all' ? 'bg-blue-900 text-white font-bold' : 'bg-gray-100 text-gray-700 hover:bg-gray-200' }}">Tous</a>
            <a href="{{ route('admin.dashboard', array_merge(request()->query(), ['type' => 'child_missing'])) }}" class="px-3 py-1 text-xs rounded-full {{ request('type') === 'child_missing' ? 'bg-blue-600 text-white font-bold' : 'bg-blue-50 text-blue-700 hover:bg-blue-100' }}">{{ __('Enfants') }}</a>
            <a href="{{ route('admin.dashboard', array_merge(request()->query(), ['type' => 'adult_missing'])) }}" class="px-3 py-1 text-xs rounded-full {{ request('type') === 'adult_missing' ? 'bg-purple-600 text-white font-bold' : 'bg-purple-50 text-purple-700 hover:bg-purple-100' }}">{{ __('Adultes') }}</a>
            <a href="{{ route('admin.dashboard', array_merge(request()->query(), ['type' => 'wanted_person'])) }}" class="px-3 py-1 text-xs rounded-full {{ request('type') === 'wanted_person' ? 'bg-red-600 text-white font-bold' : 'bg-red-50 text-red-700 hover:bg-red-100' }}">{{ __('Recherchés') }}</a>
        </div>
        <div class="flex items-center gap-2">
            <span class="text-sm font-medium text-gray-700">{{ __('Statut:') }}</span>
            <a href="{{ route('admin.dashboard', array_merge(request()->query(), ['filter_status' => 'pending'])) }}" class="px-3 py-1 text-xs rounded-full {{ request('filter_status') === 'pending' ? 'bg-amber-500 text-white font-bold' : 'bg-amber-50 text-amber-700 hover:bg-amber-100' }}">{{ __('En attente') }}</a>
            <a href="{{ route('admin.dashboard', array_merge(request()->query(), ['filter_status' => 'verified'])) }}" class="px-3 py-1 text-xs rounded-full {{ request('filter_status') === 'verified' ? 'bg-emerald-600 text-white font-bold' : 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100' }}">{{ __('Validés') }}</a>
        </div>
    </div>

    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <!-- Missing Children Management -->
        <div class="bg-white shadow rounded-lg overflow-hidden">
            <div class="px-4 py-5 sm:px-6 bg-gray-50 border-bottom flex justify-between items-center">
                <h3 class="text-lg font-medium leading-6 text-gray-900">{{ __('Dossiers & Alertes') }}</h3>
                <span class="text-xs text-gray-500">{{ $children->total() }} signalement(s)</span>
            </div>
            <ul role="list" class="divide-y divide-gray-200">
                @forelse($children as $child)
                <li class="px-4 py-4 sm:px-6 hover:bg-gray-50">
                    <div class="flex items-center justify-between">
                        <div class="flex items-center space-x-3">
                            <div class="h-12 w-12 flex-shrink-0">
                                @if($child->photo_url)
                                    <img class="h-12 w-12 rounded-full object-cover" src="{{ $child->photo_url }}" alt="">
                                @else
                                    <div class="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center text-blue-500 font-bold">
                                        {{ substr($child->name, 0, 1) }}
                                    </div>
                                @endif
                            </div>
                            <div>
                                <div class="flex items-center space-x-2">
                                    <span class="text-sm font-bold text-gray-900">{{ $child->name }}</span>
                                    <span class="text-xs text-gray-500">({{ $child->age }} {{ __('ans') }})</span>
                                    
                                    @if($child->alert_type === 'wanted_person')
                                        <span class="inline-flex items-center rounded-md bg-red-100 px-2 py-0.5 text-xs font-semibold text-red-700">🚨 {{ __('Recherché') }}</span>
                                    @elseif($child->alert_type === 'adult_missing')
                                        <span class="inline-flex items-center rounded-md bg-purple-100 px-2 py-0.5 text-xs font-semibold text-purple-700">🧓 {{ __('Adulte') }}</span>
                                    @else
                                        <span class="inline-flex items-center rounded-md bg-blue-100 px-2 py-0.5 text-xs font-semibold text-blue-700">👶 {{ __('Enfant') }}</span>
                                    @endif
                                </div>
                                <div class="text-xs text-gray-500 mt-1">
                                    {{ __('Signalé par:') }} <span class="font-medium">{{ $child->user->name }}</span> • {{ $child->created_at->diffForHumans() }}
                                </div>
                            </div>
                        </div>
                        <div class="flex flex-col sm:flex-row items-end sm:items-center space-y-1 sm:space-y-0 sm:space-x-2">
                            @if(!$child->is_verified)
                                <form action="{{ route('admin.children.verify', $child) }}" method="POST">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center rounded-md bg-blue-600 px-3 py-1.5 text-xs font-bold text-white shadow-sm hover:bg-blue-700 transition" title="{{ __('Valider l\'alerte et diffuser la notification aux citoyens') }}">
                                        📢 {{ __('Valider & Diffuser') }}
                                    </button>
                                </form>
                            @else
                                <span class="inline-flex items-center rounded-md bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700 ring-1 ring-inset ring-emerald-600/20">
                                    ✓ {{ __('Diffusée') }}
                                </span>
                            @endif

                            @if($child->status === 'missing')
                                <form action="{{ route('admin.children.found', $child) }}" method="POST">
                                    @csrf
                                    <button type="submit" class="inline-flex items-center rounded-md bg-gray-100 px-2.5 py-1.5 text-xs font-semibold text-gray-700 hover:bg-green-100 hover:text-green-800 transition">
                                        {{ __('Retrouvé') }}
                                    </button>
                                </form>
                            @else
                                <span class="inline-flex items-center rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-600">
                                    {{ __('Clôturé') }}
                                </span>
                            @endif
                        </div>
                    </div>
                </li>
                @empty
                <li class="px-4 py-8 text-center text-gray-500">{{ __('Aucune alerte trouvée pour ces critères.') }}</li>
                @endforelse
            </ul>
            <div class="px-4 py-3 bg-gray-50">
                {{ $children->links() }}
            </div>
        </div>

        <!-- Recent Sighting Reports -->
        <div class="bg-white shadow rounded-lg overflow-hidden">
            <div class="px-4 py-5 sm:px-6 bg-gray-50 border-bottom">
                <h3 class="text-lg font-medium leading-6 text-gray-900">{{ __("Signalements d'aperçus récents") }}</h3>
            </div>
            <div class="flow-root">
                <ul role="list" class="divide-y divide-gray-200">
                    @forelse($stats['recent_reports'] as $report)
                    <li class="px-4 py-4 sm:px-6">
                        <div class="flex items-center space-x-4">
                            <div class="min-w-0 flex-1">
                                <p class="truncate text-sm font-medium text-gray-900">{{ __('Aperçu pour: ') }}{{ $report->missingChild->name }}</p>
                                <p class="truncate text-sm text-gray-500">{{ __('Lieu: ') }}{{ round($report->lat, 4) }}, {{ round($report->lng, 4) }}</p>
                            </div>
                            <div>
                                <span class="text-xs text-gray-400">{{ $report->created_at->diffForHumans() }}</span>
                            </div>
                        </div>
                        <p class="mt-2 text-sm text-gray-600 line-clamp-2 italic">
                            "{{ $report->description ?? __('Pas de description') }}"
                        </p>
                    </li>
                    @empty
                    <li class="px-4 py-8 text-center text-gray-500">{{ __('Aucun signalement récent.') }}</li>
                    @endforelse
                </ul>
            </div>
        </div>
    </div>

    <!-- Heatmap Section -->
    <div class="bg-white shadow rounded-lg overflow-hidden">
        <div class="px-4 py-5 sm:px-6 bg-gray-50 border-bottom flex justify-between items-center">
            <h3 class="text-lg font-medium leading-6 text-gray-900">{{ __('Zones de Danger (Heatmap)') }}</h3>
            <span class="text-xs text-gray-500">{{ __('Visualisation basée sur les derniers signalements') }}</span>
        </div>
        <div id="map" class="h-96 w-full"></div>
    </div>
</div>

<!-- Leaflet & Heatmap Script -->
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<script src="https://cdn.jsdelivr.net/npm/leaflet.heat@0.2.0/dist/leaflet-heat.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        var map = L.map('map').setView([0, 0], 2);
        
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
        }).addTo(map);

        var heatData = [
            @foreach($dangerZones as $zone)
                [{{ $zone->lat }}, {{ $zone->lng }}, {{ $zone->intensity }}],
            @endforeach
        ];

        if (heatData.length > 0) {
            var heat = L.heatLayer(heatData, {
                radius: 25,
                blur: 15,
                maxZoom: 17,
                gradient: {0.4: 'blue', 0.65: 'lime', 1: 'red'}
            }).addTo(map);
            
            // Center map on first data point if available
            map.setView([heatData[0][0], heatData[0][1]], 12);
        }
    });
</script>
@endsection
