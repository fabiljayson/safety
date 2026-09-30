<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>{{ __('Rapport des Enfants Disparus') }}</title>
    <style>
        body { font-family: sans-serif; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .header { text-align: center; margin-bottom: 30px; }
        .status { font-weight: bold; color: red; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ SAFE CHILD</h1>
        <h2>{{ __('Rapport Officiel des Personnes et Enfants Recherchés') }}</h2>
        <p>{{ __('Généré le :') }} {{ now()->format('d/m/Y H:i') }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>{{ __('Type') }}</th>
                <th>{{ __('Nom') }}</th>
                <th>{{ __('Âge') }}</th>
                <th>{{ __('Dernier lieu connu') }}</th>
                <th>{{ __('Date') }}</th>
                <th>{{ __('Statut') }}</th>
            </tr>
        </thead>
        <tbody>
            @foreach($children as $child)
            <tr>
                <td>
                    @if($child->alert_type === 'wanted_person')
                        {{ __('Recherché') }}
                    @elseif($child->alert_type === 'adult_missing')
                        {{ __('Adulte disparu') }}
                    @else
                        {{ __('Enfant disparu') }}
                    @endif
                </td>
                <td><strong>{{ $child->name }}</strong></td>
                <td>{{ $child->age }} {{ __('ans') }}</td>
                <td>{{ round($child->disappearance_lat, 4) }}, {{ round($child->disappearance_lng, 4) }}</td>
                <td>{{ $child->disappeared_at ? $child->disappeared_at->format('d/m/Y H:i') : '-' }}</td>
                <td class="status">{{ $child->is_verified ? __('Diffusée') : __('En attente') }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
