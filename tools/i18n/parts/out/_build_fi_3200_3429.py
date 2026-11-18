# -*- coding: utf-8 -*-
"""Build fi_3200_3429.json — Finnish translations for catalog indices 3200-3429."""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "out", "fi_3200_3429.json")

sources = {}
for name in ("src_3200_3399.json", "src_3400_3429.json"):
    with open(os.path.join(ROOT, name), encoding="utf-8") as f:
        sources.update(json.load(f)["sources"])

must = json.load(open(os.path.join(ROOT, "must_fi.json"), encoding="utf-8"))

T = {
3200: "Teksti",
3201: "Teksti ei voi olla tyhjä toistotilassa.",
3202: "Tekstisisältö:",
3203: "Teksti kopioitu leikepöydälle!",
3204: "Tekstitiedostot (*.txt)",
3205: "Tekstitiedostot (*.txt)|*.txt|Kaikki tiedostot (*.*)|*.*",
3206: "Tekstiä ei löytynyt.",
3207: "Tekstiä ei löytynyt.",
3208: "AI palautti tyhjän vastauksen. Yritä uudelleen tai lyhennä näytettä.",
3209: "Python-lisäosa %s ladattiin, mutta sitä ei löytynyt sovelluskansiosta.",
3210: "Tiedosto muuttui levyllä. Pyydä agenttia uudelleen.",
3211: "Ensimmäisen rivin viimeisen numerosarjan kahdeksan viimeistä numeroa näyttävät olevan %s (usein DDMMYYYY-muotoinen päivämäärä).",
3212: "Malli pysähtyi vuororajan jälkeen.",
3213: "Tiedostojen välillä ei ole eroa.",
3214: "Tämä tiedosto on hyvin suuri. Sovellus ohittaa täyden esiskannauksen (osumien laskennan), jotta käyttöliittymä pysyy responsiivisena.",
3215: "Tämä rivi ei ole nykyisissä suodatustuloksissa.",
3216: "Tämä tila ei käytä Regexiä. Tiedosto jaetaan X yhtä suureen osaan säilyttäen kokonaiset rivit (ei katkaisuja rivin keskeltä).",
3217: "Tätä toimintoa ei voi kumota.",
3218: "Tämä teksti lisätään automaattisesti JOKAISEN luodun osatiedoston aivan alkuun.",
3219: "Tämä teksti lisätään automaattisesti JOKAISEN luodun osatiedoston aivan loppuun.",
3220: "Säikeistetty haku",
3221: "Rivien poiston kesto: %s.",
3222: "Toiminnon suorituksen kesto: %s.",
3223: "Lukuun kului: %s ms.",
3224: "Lukuun kului: %s ms. Rivejä yhteensä: %d.",
3225: "Lukuun kului: %s ms. Rivejä yhteensä: %d. Lukusäikeitä: %d.",
3226: "Tyhjennä toiminnon ajastimen loki",
3227: "Kopioidaanko tämä teksti leikepöydälle?",
3228: "Napsauta hiiren kakkospainikkeella kopioidaksesi tämän tekstin leikepöydälle",
3229: "Vihje",
3230: "Vihje: peruuta painamalla ESC.",
3231: "Vihjeitä: regexiä sovelletaan rivi kerrallaan; ^ tarkoittaa kunkin rivin alkua.",
3232: "Otsikkoetuliitteen tarkistus",
3233: "Näytä/piilota sovelluskuvake",
3234: "Säilyttääksesi tiedostossa vain rivit, joissa %s:llä on korkea numeerinen arvo (esim. yli 100 arvostelua).",
3235: "Loppurivin on oltava >= aloitusrivi.",
3236: "Loppurivi:",
3237: "Tunnistaaksesi nopeasti, millä riveillä on tietty %s (kuten sarake arvolla 1).",
3238: "Jakamiseen N yhtä suureen osaan rivimäärän tai koon mukaan käytä FastFilen yhtä suurten osien työnkulkua Regexin sijaan - Regex ei voi laskea rivejä koko tiedostosta yhdessä Test-kutsussa.",
3239: "Asti:",
3240: "Vaihda rivinvaihto (Ctrl+W)",
3241: "Liian monta riviä vietäväksi tiedostoon (%d; enintään %d). Pienennä aluetta.",
3242: "Liian monta riviä vietäväksi leikepöydälle (%d; enintään %d). Pienennä aluetta tai tallenna tekstitiedostoon.",
3243: "Vertaa / yhdistä + historia (Ctrl+Shift+H)",
3244: "Suodatin / Grep (Ctrl+L)",
3245: "Etsi tekstiä (Ctrl+F)",
3246: "Etsi ja korvaa (Ctrl+H)",
3247: "Näytä leijuvat vihjeet riveillä ja kaikissa säätimissä (avustaja, suodatin, työkalurivi)",
3248: "Näytä tab/välilyönti/CR/LF-merkit (Ctrl+Alt+M)",
3249: "Rivinvaihto (Ctrl+W)",
3250: "Suurenna listan fonttia (Ctrl+Plus)",
3251: "Pienennä listan fonttia (Ctrl+Minus)",
3252: "Python-makro",
3253: "Avaa Python-makropaneeli muuntaaksesi tiedoston rivit skriptillä (Ctrl+Alt+E)",
3254: "Työkalut",
3255: "Tyhjennä haku",
3256: "Ulkoasu",
3257: "Haku",
3258: "Jaa ja pura",
3259: "Hakutyökalut...",
3260: "Ctrl+Shift+F",
3261: "Ctrl+Alt+K",
3262: "Valitse työkalu",
3263: "Ylätyökalurivi",
3264: "Tiedostovaihtoehdot (vie, valitse, suodata, tyhjennä...)",
3265: "Merkkejä yhteensä:",
3266: "Rivejä yhteensä:",
3267: "Litteraatti tyhjennetty",
3268: "Litteraatti viety kohteeseen: ",
3269: "Kokeile toista lähdetiedostoa tai mallitilaa.",
3270: "Oppaat: ",
3271: "Kahden tiedoston diff",
3272: "Kirjoita arvo tähän.",
3273: "Kirjoita etsittävät tiedostonimikuviot.",
3274: "Kirjoita kansiot, joista tiedostoja etsitään.",
3275: "Kirjoita tai valitse tiedostopolku.",
3276: "Kirjoita tiedostoista etsittävä tekstisisältö.",
3277: "Kirjoita ladatuilta riveiltä etsittävä teksti.",
3278: "Kirjoita etsittävä teksti:",
3279: "Kirjoitettu teksti:",
3280: "URL-osoitteet",
3281: "Kumoa",
3282: "Kumotaanko poisto rivillä %d? Poistettu rivi palautetaan.",
3283: "Kumotaanko poisto rivillä %d? Rivi palautetaan: \"%s\"",
3284: "Kumotaanko muokkaus rivillä %d? Rivi palautetaan aiempaan sisältöönsä.",
3285: "Kumotaanko muokkaus rivillä %d? Rivi palautetaan muotoon: \"%s\"",
3286: "Kumoaminen epäonnistui.",
3287: "Kumotaanko lisäys rivillä %d? Lisätty rivi poistetaan.",
3288: "Kumoa rivitäyttö (%d rivi(ä) rivillä %d)",
3289: "Kumotaanko %d tyhjän rivin rivitäyttö rivillä %d? Lisätyt rivit poistetaan.",
3290: "Kumotaanko %d rivin liittäminen alkaen rivistä %d? Liitetyt rivit poistetaan.",
3291: "Kumotaanko viimeinen muutos rivillä %d?",
3292: "Kumoa: poista rivi ",
3293: "Kumoa: lisää rivi ",
3294: "Kumoa: poista %d rivitäyttörivi(ä) riviltä %d",
3295: "Kumoa: poista %d liitettyä rivi(ä) riviltä %d",
3296: "Kumoa: palauta rivi ",
3297: "Tuntematon virhe.",
3298: "Python-lisäosaa ei tueta automaattiseen lataukseen.",
3299: "Regex-lippua ei tueta: %s",
3300: "Päivitetään rivi-indeksiä...",
3301: "Paina Käytä-painikkeita tallentaaksesi yhdistetyt rivit levylle (erissä). Vihreät (samat) rivit ohitetaan.",
3302: "Kirjoita ensin hakuteksti Osumat-paneeliin (tai käytä Ctrl+F).",
3303: "Käytä Esikatselua ennen koko tiedoston käsittelyä.",
3304: "Käytä Python-makroja uusilla riveillä",
3305: "Käytä eri tekstiä jokaiselle uudelle riville",
3306: "Käytä editorissa",
3307: "Hyödyllinen vain %s:n ja %s:n poimimiseen kustakin rivistä.",
3308: "Hyödyllisiä linkkejä:",
3309: "Hyödyllinen anonymisoimaan tai normalisoimaan sisältöä kaikilla riveillä (esimerkiksi poistamaan numeerisia URL-päätteitä).",
3310: "Hyödyllinen säilyttämään vain säännön täyttävät rivit (esimerkiksi yhden alueen rivit).",
3311: "Hyödyllinen nollajaksojen väliin upotettujen tunnusten ja summien otantaan.",
3312: "Hyödyllinen kunkin rivin nopeaan validointiin (esimerkiksi jos rivi säilyttää odotetun CSV-rakenteen).",
3313: "Hyödyllinen, kun sarake sisältää URL-osoitteita; ankkurit voivat tarvita lainausmerkkejä tai lisäerottimia tiedostollesi.",
3314: "Hyödyllinen, kun haluat poimia tiettyjä tokeneita kustakin rivistä (esimerkiksi tunnuksia ja URL-osoitteita).",
3315: "Käyttää lookbehindia ohittaakseen verkkotunnuksen ja kaapatakseen vain URL-polun.",
3316: "VBScript.RegExp ei ole käytettävissä (virheellinen malli tai puuttuva komponentti).",
3317: "Validoi päivämäärät kohteessa",
3318: "Versiohistoria",
3319: "Näyttökoodaus (lista):",
3320: "Näyttökoodaus: oletus (lista seuraa tunnistettua BOM/heuristiikkaa).",
3321: "Näyttökoodaus: pakotettu (vain listan dekoodaus; tiedosto levyllä ennallaan).",
3322: "Näytä: ANSI (raaka / järjestelmä)",
3323: "Näytä: OLETUS (tunnistettu)",
3324: "Näytä: UTF-16 BE",
3325: "Näytä: UTF-16 LE",
3326: "Näytä: UTF-32 BE",
3327: "Näytä: UTF-32 LE",
3328: "Näytä: UTF-8",
3329: "Virtuaalinen",
3330: "Näkyvien merkkien selite:",
3331: "Odotetaan moottorin tulostetta...",
3332: "Odotetaan Pythonia...",
3333: "Varoitus",
3334: "FastFile: käyttöliittymä ei ole vastannut ~%u s.",
3335: "Toiminto: %s",
3336: "Yritetäänkö peruuttaa taustatyö (Etsi/Suodatin/indeksointi)?",
3337: "FastFile - mahdollinen jumiutuminen",
3338: "FastFile: kriittinen muistinkäyttö (~%.0f MB). Peruutetaanko raskas työ ja vapautetaanko välimuisti?",
3339: "FastFile - muisti",
3340: "Mitä se tekee:",
3341: "Mitä viedään",
3342: "Kun käytössä, Korvaa kaikki ja valittujen rivien eräpoisto voivat käsitellä tiedoston rivialineisiin segmentteihin (väliaikaiset osat) ja yhdistää sitten. Voi vähentää muistihuippua hyvin suurilla tiedostoilla. Korvaa kaikki: segmenttirajan ylittävä hakuteksti ei välttämättä täsmää.",
3343: "Kun tämä malli löytyy riviltä, nykyinen tiedosto tallennetaan ja uusi jaettu tiedosto aloitetaan.",
3344: "Koko sana",
3345: "Koko tiedosto käytettävissä: %s riviä (sivutettu luku, vähän muistia).",
3346: "Koko sana",
3347: "Rivinvaihto (PÄÄLLÄ)",
3348: "Rivinvaihto (visuaalinen):",
3349: "Käsitellään...",
3350: "Kirjoita",
3351: "Kirjoita ensin kehote.",
3352: "Kirjoitus",
3353: "XML-tyyppisiä rivejä havaittu; käytetään ensimmäistä tunnistetta <%s ...>.",
3354: "KYLLÄ = rakenna rivi-indeksi nyt (täysi levyajo, tarkat rivinumerot).",
3355: "KYLLÄ = rakenna rivi-indeksi nyt (suositus).",
3356: "Kyllä",
3357: "Voit vetää ja pudottaa lähdetiedoston tähän ikkunaan.",
3358: "Voit käyttää valintaikkunan Esikatselu-painiketta ottaaksesi osumia nopeasti.",
3359: "Ensimmäinen rivisi alkaa kuudellatoista peräkkäisellä numerolla. Ne on ryhmitelty tähän kahdeksi kahdeksan numeron lohkoksi (yleistä päivämäärille tai tunnuksille). Säädä ryhmittelyä, jos määrityksesi nimeää eri kenttäleveyksiä.",
3360: "Etsitään viimeistä riviä (lasketaan tiedoston rivinvaihtoja, odota)...",
3361: "Tiedoston loppu (~rivi %d, tavu %s); suhteellinen arvio)",
3362: "Tiedoston loppu (rivi ~%d, tavu %s); välimuistissa)",
3363: "Su&urenna (lista)",
3364: "Pie&nennä (lista)",
3365: "[Riviesikatselu rajoitettu %s tavuun suorituskyvyn vuoksi; tiedoston rivi yhteensä %s tavua.]",
3366: "[Rivi katkaistu näyttöä varten: yhteensä %s tavua.]",
3367: "[ReplaceAll] ",
3368: "[ReplaceAll] Virhe: ",
3369: "[ReplaceAll] Segmentoitu tuloste puuttuu.",
3370: "[ReplaceAll] Segmentoitu osa epäonnistui.",
3371: "[Tallennushuomautus] OLETUS seuraa tunnistusta; pakotettu näkymä muuttaa vain listan dekoodausta, kunnes toiminto kirjoittaa tiedoston uudelleen levylle.",
3372: "[Skannaus] %d ei-tyhjää riviä (enintään %d), erotin [%s], kenttiä: %d.",
3373: "[Skannaus] Perustuu ensimmäisiin %d ei-tyhjään riviin (enintään %d). Tunnistettu erotin [%s], kenttiä: %d.",
3374: "[Skannaus] Perustuu tämän tiedoston ensimmäisiin %d luettuun ei-tyhjään riviin (enintään %d). Asettelu: kiinteälevyinen / sijaintipohjainen (vähän erotinmerkkejä rivillä 1).",
3375: "[tiedosto] %s",
3376: "[kansio] %s",
3377: "animaatio",
3378: "sininen = muutettu",
3379: "tavua",
3380: "muuta",
3381: "Poista",
3382: "sama",
3383: "tiedostoa luotu onnistuneesti.",
3384: "suodata",
3385: "vihreä = sama",
3386: "lisää",
3387: "rivit",
3388: "ladataan AI-tukea ...",
3389: "osuma",
3390: "lisää teknisiä tietoja ...",
3391: "enimmäkseen tosi; epätodet rivit osoittavat muita otsikoita",
3392: "punainen = poistettu (vasen)",
3393: "regex",
3394: "Korvaa",
3395: "korvaukset",
3396: "vast: ",
3397: "tallennettu",
3398: "todet rivit sisältävät tiedostosta otettua alue-/kaupunkitekstiä",
3399: "todet rivit sisältävät tiedostosta otettua erikoisalatekstiä",
3400: "keltainen = lisätty (oikea)",
3401: "hindi",
3402: "venäjä",
3403: "korea",
3404: "hollanti",
3405: "turkki",
3406: "ukraina",
3407: "Kysy AI:lta",
3408: "Vertaa / yhdistä",
3409: "Tiedostosi on valmis. Valitse, mitä haluaisit tehdä seuraavaksi.",
3410: "Sulje",
3411: "Älä näytä tätä opasta uudelleen",
3412: "Muokkaa rivejä",
3413: "Yhdistä tiedostot",
3414: "Näytä seuraavan vaiheen opas tiedoston lukemisen jälkeen",
3415: "Valmis seuraavaan vaiheeseen?",
3416: "Näytä opas nyt",
3417: (
    "VIIMEISIMMÄT PÄIVITYKSET (v3.0.5.255 – v3.0.5.261)\r\n"
    "---------------------------------------------------------------\r\n"
    "  Käyttöliittymässä on nyt 22 kieltä, mukaan lukien hindi, venäjä, korea,\r\n"
    "    hollanti, turkki ja ukraina. Hindi käyttää vasemmalta oikealle etenevää asettelua.\r\n"
    "  Yhtä suurten osien käsittely lukee muistiin kartoitettuja lohkoja lataamatta\r\n"
    "    koko tiedostoa; jakovälilehti pysyy auki, kun työ valmistuu.\r\n"
    "  Tiedoston lukemisen jälkeen seuraavan vaiheen opas ehdottaa hyödyllisiä toimintoja.\r\n"
    "    Avaa se uudelleen Asetuksissa tai poista se käytöstä sieltä.\r\n"
    "  Muokkausvalikon ja istuntohistorian sanamuodot lokalisoitiin.\r\n"
    "  Opas ja Asetukset uudistettiin; opas alustuu\r\n"
    "    ilman välkkymistä tai tiedoston lukemisen keskeyttämistä.\r\n"
),
3418: "thai",
3419: "kreikka",
3420: "norja",
3421: "ruotsi",
3422: "tanska",
3423: "islanti",
3424: "Seuraava vaihe",
3425: "Näytä seuraavan vaiheen opas.",
3426: (
    "VIIMEISIMMÄT PÄIVITYKSET (v3.0.5.262 – v3.0.5.265)\r\n"
    "---------------------------------------------------------------\r\n"
    "  Thai, kreikka, norja, ruotsi, tanska ja islanti tuovat\r\n"
    "    käyttöliittymän 28 kieleen. Kaikki kuusi luetaan vasemmalta oikealle.\r\n"
    "  Seuraavat vaiheet seuraavat nykyistä toimintaa, kuten etsi, suodata,\r\n"
    "    jaa, yhdistä tai lue, eikä yhtä kiinteää listaa.\r\n"
    "  Jokainen toiminto tarjoaa enemmän jatkotoimia.\r\n"
    "  Kopioi-painikkeen vasemmalla oleva painike avaa seuraavan vaiheen oppaan uudelleen.\r\n"
),
3427: (
    "VIIMEISIMMÄT PÄIVITYKSET (v3.0.5.266 – v3.0.5.268)\r\n"
    "---------------------------------------------------------------\r\n"
    "  Seuraavan vaiheen opas on lyhyempi, joten tiedostolista pysyy näkyvissä.\r\n"
    "  Lue-kuvake on tiedostopolun kentässä, tyhjennys-X:n vasemmalla.\r\n"
    "  Se käyttää samaa merkkiä kuin työkalurivin Lue ja lataa kyseisen polun.\r\n"
),
3428: "suomi",
3429: "vietnam",
}

# Apply must overrides in range
must_t = must.get("translations", {})
must_u = must.get("unchanged", {})
for k, v in must_t.items():
    ik = int(k)
    if 3200 <= ik <= 3429:
        T[ik] = v

unchanged = {}
for ik, text in T.items():
    src = sources[str(ik)]
    if text == src:
        reason = must_u.get(str(ik))
        if not reason:
            if ik in (3260, 3261):
                reason = "Keyboard shortcut chord kept unchanged."
            elif ik == 3367:
                reason = "Technical ReplaceAll log tag prefix kept unchanged."
            elif ik == 3393:
                reason = "Short UI token 'regex' kept per glossary."
            else:
                reason = "Source equals Finnish translation."
        unchanged[str(ik)] = reason

missing = [i for i in range(3200, 3430) if i not in T]
extra = [i for i in T if i < 3200 or i > 3429]
assert not missing, f"missing {missing}"
assert not extra, f"extra {extra}"

# Validate pipes, format-ish tokens, whitespace, crlf
import re
fmt_re = re.compile(r"%\d*\.?\d*[sduxf]|%%", re.I)
errors = []
for i in range(3200, 3430):
    s = sources[str(i)]
    t = T[i]
    if s[: len(s) - len(s.lstrip())] != t[: len(t) - len(t.lstrip())]:
        errors.append(f"{i}: leading ws")
    if s[len(s.rstrip()):] != t[len(t.rstrip()):]:
        # compare trailing whitespace chars
        sw = len(s) - len(s.rstrip())
        tw = len(t) - len(t.rstrip())
        if s[len(s) - sw :] != t[len(t) - tw :]:
            errors.append(f"{i}: trailing ws {repr(s[len(s)-sw:])} vs {repr(t[len(t)-tw:])}")
    if s.count("|") != t.count("|"):
        errors.append(f"{i}: pipes {s.count('|')} vs {t.count('|')}")
    if s.count("\r\n") != t.count("\r\n"):
        errors.append(f"{i}: crlf {s.count(chr(13)+chr(10))} vs {t.count(chr(13)+chr(10))}")
    sf = fmt_re.findall(s)
    tf = fmt_re.findall(t)
    if sf != tf:
        errors.append(f"{i}: format {sf} vs {tf}")
    if t.strip() == "" and s.strip() != "":
        errors.append(f"{i}: empty")

# pair checks
pairs = [(3344, 3346), (3381, 3381), (3394, 3394)]
assert T[3344] == T[3346] == "Koko sana"
assert T[3381] == "Poista"
assert T[3394] == "Korvaa"

out = {
    "translations": {str(i): T[i] for i in range(3200, 3430)},
    "unchanged": unchanged,
}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8", newline="\n") as f:
    json.dump(out, f, ensure_ascii=False, indent=2)
    f.write("\n")

print("wrote", OUT)
print("translations", len(out["translations"]))
print("unchanged", len(out["unchanged"]), sorted(out["unchanged"]))
if errors:
    print("ERRORS:")
    for e in errors:
        print(" ", e)
else:
    print("validation OK")
