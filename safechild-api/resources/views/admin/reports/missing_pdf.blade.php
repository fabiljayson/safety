<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Rapport des Enfants Disparus</title>
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
        <h2>Rapport Officiel des Personnes et Enfants Recherchés</h2>
        <p>Généré le : {{ now()->format('d/m/Y H:i') }}</p>
    </div>

    <table>
        <thead>
            <tr>
                <th>Type</th>
                <th>Nom</th>
                <th>Âge</th>
                <th>Dernier lieu connu</th>
                <th>Date</th>
                <th>Statut</th>
            </tr>
        </thead>
        <tbody>
            @foreach($children as $child)
            <tr>
                <td>
                    @if($child->alert_type === 'wanted_person')
                        Recherché
                    @elseif($child->alert_type === 'adult_missing')
                        Adulte disparu
                    @else
                        Enfant disparu
                    @endif
                </td>
                <td><strong>{{ $child->name }}</strong></td>
                <td>{{ $child->age }} ans</td>
                <td>{{ round($child->disappearance_lat, 4) }}, {{ round($child->disappearance_lng, 4) }}</td>
                <td>{{ $child->disappeared_at ? $child->disappeared_at->format('d/m/Y H:i') : '-' }}</td>
                <td class="status">{{ $child->is_verified ? 'Diffusé' : 'En attente' }}</td>
            </tr>
            @endforeach
        </tbody>
    </table>
</body>
</html>
