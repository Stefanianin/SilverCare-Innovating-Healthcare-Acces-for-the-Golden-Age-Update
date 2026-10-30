# SilverCare+

Aplicație pentru persoană în vârstă: autentificare, dicționar de cardiologie, localizare în casă și apel la ambulanță (112).

Aplicația nu pune un diagnostic și nu prescrie medicamente. La urgență se sună la 112.

## Pornire în Xcode

1. Deschide `SilverCareN.xcodeproj` (proiectul albastru), nu un fișier `.swift` singur.
2. Sus, lângă Run, alege schema **SilverCareN** și simulatorul **iPhone 17**.
3. Apasă Run.

Pe Mac și pe simulator apelul `112` nu pornește. Aplicația arată camera și coordonatele GPS, ca să poată fi citite dispecerului. Pe un iPhone real se deschide aplicația Telefon. Acceptă permisiunea de locație, altfel rămâne doar camera aleasă din casă.

## Utilizare

1. **Autentificare.** La prima deschidere: *Cont nou, cu orice nume*. Numele nu este fix. Parola are cel puțin 4 caractere. La următoarele deschideri se intră cu același nume și aceeași parolă. *Ieșire* revine la autentificare.
2. **Acasă.** Se scriu simptomele separate prin virgulă, de exemplu `durere în piept, lipsă de aer`. Aplicația caută în dicționar, arată afecțiunile posibile și le spune cu voce tare. Dacă gravitatea orientativă este 8 sau mai mare, întreabă dacă se sună la 112.
3. **Dicționar.** Se caută un diagnostic sau un simptom. *Spune posibilele* le citește. O atingere deschide simptomele și recomandarea.
4. **Casă.** Se atinge camera în care se află persoana: dormitor, sufragerie, bucătărie, baie, hol sau balcon. Telefonul nu vede prin pereți, de aceea camera se alege aici și rămâne salvată. GPS-ul și harta arată poziția casei.
5. **Sună ambulanța.** Pe iPhone pornește `tel:112` și spune numele persoanei, camera și coordonatele.

Pulsul, temperatura și menopauza se modifică pe fișa de acasă și rămân salvate pentru contul respectiv.

## Fișiere

| Fișier | Rol |
| --- | --- |
| `SilverCareNApp.swift` | Punctul de intrare |
| `ContentView.swift` | Ecranul de după autentificare: fișă, simptome, apel |
| `LoginView.swift` | Creare cont și intrare |
| `SessionStore.swift` | Conturile salvate pe telefon |
| `DictionaryView.swift` | Căutarea în dicționarul de cardiologie |
| `CardiologyDictionary.swift` | Diagnosticele și simptomele |
| `HouseLocationView.swift` | Camera din casă și harta |
| `LocationManager.swift` | GPS și camera salvată |
| `SpeechHelper.swift` | Citirea cu voce tare, în română |
| `Models.swift` | Modelele de date |

Conturile stau local, în aplicație. Parola este păstrată ca hash, nu ca text.
