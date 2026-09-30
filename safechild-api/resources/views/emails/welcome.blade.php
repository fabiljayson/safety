<x-mail::message>
# {{ __('Welcome aboard, :name!', ['name' => $user->name]) }}

{{ __("Thanks for joining the **SafeChild** community. 🛡️") }}

{{ __('Your account has been created successfully. Together we strengthen vigilance for the safety of our children.') }}

<x-mail::button :url="config('app.url')">
{{ __('Open the platform') }}
</x-mail::button>

{{ __('If you need to, you can now:') }}
- {{ __('Report a disappearance in real time.') }}
- {{ __('Consult the map of active alerts.') }}
- {{ __('Take part in community discussions.') }}

{{ __('Thank you for your commitment,') }}
{{ __('The :app team', ['app' => config('app.name')]) }}
</x-mail::message>
