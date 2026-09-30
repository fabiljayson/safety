<?php

namespace Tests\Feature;

use FilesystemIterator;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use Tests\TestCase;

/**
 * Guards the admin panel's translations.
 *
 * A key that is used in a Blade view but missing from a language file renders
 * as the raw French source string in every locale, which is invisible in the
 * console and easy to reintroduce when adding markup.
 */
class TranslationCoverageTest extends TestCase
{
    /** @return array<int, string> */
    private function keysUsedInViews(): array
    {
        $keys = [];

        // Recursive, because glob() does not support a ** pattern and would
        // silently skip views/admin/reports/*.blade.php and the root views.
        $views = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator(resource_path('views'), FilesystemIterator::SKIP_DOTS)
        );

        foreach ($views as $view) {
            if (! $view->isFile() || $view->getExtension() !== 'php') {
                continue;
            }

            $source = (string) file_get_contents($view->getPathname());

            foreach (['single' => "'", 'double' => '"'] as $quote) {
                $pattern = '/__\(\s*'.preg_quote($quote, '/').'((?:[^'.preg_quote($quote, '/').'\\\\]|\\\\.)*)'.preg_quote($quote, '/').'/';
                preg_match_all($pattern, $source, $matches);

                foreach ($matches[1] as $match) {
                    // Undo PHP single-quote escaping to get the real key.
                    $keys[] = str_replace(["\\'", '\\\\'], ["'", '\\'], $match);
                }
            }

            preg_match_all('/@lang\(\s*\'((?:[^\'\\\\]|\\\\.)*)\'/', $source, $langMatches);
            foreach ($langMatches[1] as $match) {
                $keys[] = str_replace("\\'", "'", $match);
            }
        }

        return array_values(array_unique($keys));
    }

    /** @return array<string, string> */
    private function langFile(string $locale): array
    {
        $path = lang_path($locale.'.json');

        $this->assertFileExists($path, "Missing language file for {$locale}");

        return json_decode((string) file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
    }

    public function test_every_key_used_in_a_view_exists_in_both_locales(): void
    {
        $english = $this->langFile('en');
        $french = $this->langFile('fr');

        $missingEnglish = array_diff($this->keysUsedInViews(), array_keys($english));
        $missingFrench = array_diff($this->keysUsedInViews(), array_keys($french));

        $this->assertSame(
            [],
            array_values($missingEnglish),
            'These keys are used in a view but missing from lang/en.json'
        );
        $this->assertSame(
            [],
            array_values($missingFrench),
            'These keys are used in a view but missing from lang/fr.json'
        );
    }

    public function test_english_and_french_files_define_the_same_keys(): void
    {
        $english = $this->langFile('en');
        $french = $this->langFile('fr');

        $this->assertSame(
            [],
            array_values(array_diff(array_keys($english), array_keys($french))),
            'lang/en.json defines keys that lang/fr.json does not'
        );
        $this->assertSame(
            [],
            array_values(array_diff(array_keys($french), array_keys($english))),
            'lang/fr.json defines keys that lang/en.json does not'
        );
    }

    public function test_english_values_are_not_left_in_french(): void
    {
        // Keys whose source text is French must not be echoed back verbatim in
        // lang/en.json, otherwise English visitors see French. Keys written in
        // English at the source (the welcome email) are legitimately identical.
        $looksFrench = '/[éèêàûôçÉÈÊÀÇ]|\b(le|la|les|des|une|recherche|enfants|adultes|personnes|disparus|valide|valider|clôture|statut|attente|retouvé|tableau|connexion|citoyen)\b/i';

        $untranslated = [];
        foreach ($this->langFile('en') as $key => $value) {
            if ($value === $key && preg_match($looksFrench, $key)) {
                $untranslated[] = $key;
            }
        }

        $this->assertSame([], $untranslated, 'These English values are still the French source string');
    }
}
