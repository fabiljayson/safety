<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Renders the server-rendered pages in both locales.
 *
 * The translation files are covered by TranslationCoverageTest; this asserts
 * the outcome a visitor actually sees, so a locale that silently falls back to
 * the French source string is caught at the HTTP level.
 */
class RenderI18nTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_admin_login_page_renders_in_english_by_default(): void
    {
        $response = $this->get('/admin/login');

        $response->assertOk();
        $response->assertSee('Log In');
        $response->assertSee('Password');
        $response->assertDontSee('Mot de passe');
    }

    public function test_the_admin_login_page_follows_the_session_locale(): void
    {
        $response = $this->withSession(['locale' => 'fr'])->get('/admin/login');

        $response->assertOk();
        $response->assertSee('Mot de passe');
        $response->assertDontSee('Password');
    }

    public function test_the_landing_page_renders_in_english_by_default(): void
    {
        $response = $this->get('/');

        $response->assertOk();
        $response->assertSee('VIEW LIVE MAP');
        $response->assertDontSee('VOIR LA CARTE EN DIRECT');
    }

    public function test_the_landing_page_follows_the_session_locale(): void
    {
        $response = $this->withSession(['locale' => 'fr'])->get('/');

        $response->assertOk();
        $response->assertSee('VOIR LA CARTE EN DIRECT');
    }
}
