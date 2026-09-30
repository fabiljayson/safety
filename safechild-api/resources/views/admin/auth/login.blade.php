<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}" class="h-full bg-blue-900">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ __('SafeChild Admin - Connexion') }}</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="h-full relative">
    <!-- Language Toggle Button -->
    <div class="absolute top-4 right-4">
        @if(app()->getLocale() == 'fr')
            <a href="{{ route('lang.switch', 'en') }}" class="flex items-center space-x-1.5 bg-blue-800 text-white hover:bg-blue-700 px-3 py-1.5 rounded-lg border border-blue-700 shadow-lg transition" title="Switch to English">
                <span class="text-lg">🇬🇧</span>
                <span class="font-bold text-xs">EN</span>
            </a>
        @else
            <a href="{{ route('lang.switch', 'fr') }}" class="flex items-center space-x-1.5 bg-blue-800 text-white hover:bg-blue-700 px-3 py-1.5 rounded-lg border border-blue-700 shadow-lg transition" title="{{ __('Passer en Français') }}">
                <span class="text-lg">🇫🇷</span>
                <span class="font-bold text-xs">FR</span>
            </a>
        @endif
    </div>

    <div class="flex min-h-full flex-col justify-center px-6 py-12 lg:px-8">
        <div class="sm:mx-auto sm:w-full sm:max-w-sm">
            <div class="text-center">
                <span class="text-white text-5xl">🛡️</span>
                <h2 class="mt-6 text-center text-3xl font-bold leading-9 tracking-tight text-white">{{ __('SafeChild Autorités') }}</h2>
                <p class="mt-2 text-blue-200">{{ __("Interface d'administration et de certification") }}</p>
            </div>
        </div>

        <div class="mt-10 sm:mx-auto sm:w-full sm:max-w-sm">
            <div class="bg-white px-8 py-10 shadow-2xl rounded-2xl">
                <form class="space-y-6" action="{{ route('admin.login') }}" method="POST">
                    @csrf
                    <div>
                        <label for="email" class="block text-sm font-medium leading-6 text-gray-900">{{ __('Email professionnel') }}</label>
                        <div class="mt-2">
                            <input id="email" name="email" type="email" required class="block w-full rounded-md border-0 py-2.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6 px-3" value="{{ old('email') }}">
                        </div>
                        @error('email')
                            <p class="mt-2 text-sm text-red-600">{{ $message }}</p>
                        @enderror
                    </div>

                    <div>
                        <div class="flex items-center justify-between">
                            <label for="password" class="block text-sm font-medium leading-6 text-gray-900">{{ __('Mot de passe') }}</label>
                        </div>
                        <div class="mt-2">
                            <input id="password" name="password" type="password" required class="block w-full rounded-md border-0 py-2.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm sm:leading-6 px-3">
                        </div>
                    </div>

                    <div>
                        <button type="submit" class="flex w-full justify-center rounded-md bg-blue-900 px-3 py-3 text-sm font-semibold leading-6 text-white shadow-sm hover:bg-blue-800 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600">
                            {{ __('Se connecter') }}
                        </button>
                    </div>
                </form>
            </div>
            
            <p class="mt-10 text-center text-sm text-blue-200">
                {{ __('Accès réservé aux services de sécurité certifiés.') }}
            </p>
        </div>
    </div>
</body>
</html>
