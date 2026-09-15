<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}" class="h-full bg-gray-50">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SafeChild Admin - @yield('title')</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="h-full">
    <div class="min-h-full">
        <nav class="bg-blue-900">
            <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                <div class="flex h-16 items-center justify-between">
                    <div class="flex items-center">
                        <div class="shrink-0">
                            <span class="text-white font-bold text-xl">🛡️ SAFE CHILD ADMIN</span>
                        </div>
                        <div class="hidden md:block">
                            <div class="ml-10 flex items-baseline space-x-4">
                                <a href="{{ route('admin.dashboard') }}" class="bg-blue-800 text-white rounded-md px-3 py-2 text-sm font-medium">{{ __('Tableau de bord') }}</a>
                            </div>
                        </div>
                    </div>
                    <div class="hidden md:block">
                        <div class="ml-4 flex items-center md:ml-6 space-x-4">
                            <!-- Language Toggle Button -->
                            @if(app()->getLocale() == 'fr')
                                <a href="{{ route('lang.switch', 'en') }}" class="flex items-center space-x-1.5 bg-blue-800 hover:bg-blue-700 px-2.5 py-1 rounded text-white border border-blue-700 transition" title="Switch to English">
                                    <span class="text-sm">🇬🇧</span>
                                    <span class="font-bold text-xs">EN</span>
                                </a>
                            @else
                                <a href="{{ route('lang.switch', 'fr') }}" class="flex items-center space-x-1.5 bg-blue-800 hover:bg-blue-700 px-2.5 py-1 rounded text-white border border-blue-700 transition" title="Passer en Français">
                                    <span class="text-sm">🇫🇷</span>
                                    <span class="font-bold text-xs">FR</span>
                                </a>
                            @endif

                            <span class="text-white text-sm">{{ Auth::user()->name }}</span>
                            <form action="{{ route('admin.logout') }}" method="POST" class="inline">
                                @csrf
                                <button type="submit" class="text-blue-200 hover:text-white text-sm font-medium">{{ __('Déconnexion') }}</button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </nav>

        <header class="bg-white shadow">
            <div class="mx-auto max-w-7xl px-4 py-6 sm:px-6 lg:px-8">
                <h1 class="text-3xl font-bold tracking-tight text-gray-900">@yield('title')</h1>
            </div>
        </header>

        <main>
            <div class="mx-auto max-w-7xl py-6 sm:px-6 lg:px-8">
                @if(session('success'))
                    <div class="mb-4 bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded relative">
                        {{ session('success') }}
                    </div>
                @endif
                @yield('content')
            </div>
        </main>
    </div>
</body>
</html>
