<x-mail::message>
# Bienvenue parmi nous, {{ $user->name }} !

Merci d'avoir rejoint la communauté **SafeChild**. 🛡️

Votre compte a été créé avec succès. Ensemble, nous renforçons la vigilance pour la sécurité de nos enfants.

<x-mail::button :url="config('app.url')">
Accéder à la plateforme
</x-mail::button>

En cas de besoin, vous pouvez maintenant :
- Signaler une disparition en temps réel.
- Consulter la carte des alertes actives.
- Participer aux échanges de la communauté.

Merci pour votre engagement,  
L'équipe {{ config('app.name') }}
</x-mail::message>
