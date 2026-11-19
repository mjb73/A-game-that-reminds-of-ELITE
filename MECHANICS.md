# MECHANICS — Elite (1984) rebuild

Every number that shapes how this build plays. "spec" = the game design sheet
supplied with the request; "reference picture-N" = the supplied screenshots of
the original; "estimated" = chosen here because neither the sheet nor the
reference states it.

## Player / commander
| Value | Setting | Source |
| --- | --- | --- |
| name | Commander Jameson | spec §1 |
| starting cash | 100.0 CR | spec §1 |
| starting system | Lave (galaxy 1, index 7) | spec §1 |
| ship | Cobra Mk III | spec §1 |
| cargo hold | 20 t (35 t with large bay) | spec §1, §5 |
| fuel tank | 7.0 LY | spec §1 |
| starting missiles | 3 | spec §1 |
| starting laser | front pulse laser | spec §1 |

## Flight model
| Value | Setting | Source |
| --- | --- | --- |
| max speed | 0.35 LM (350 units/s) | estimated (reference shows LM readout) |
| acceleration | 140 units/s² | estimated |
| deceleration | 140 units/s² | estimated |
| pitch rate (max) | 1.25 rad/s | estimated |
| roll rate (max) | 2.0 rad/s | estimated |
| pitch / roll response | 5.0 and 6.0 per second (eased) | estimated |
| yaw | none — pitch and roll only | spec §2 "pitch, roll, and forward thrust (no lateral strafing or reverse thrust)" |
| views | front, rear, left, right | spec §6 |
| in-system jump (J) | disabled while mass locked | spec §2 |
| mass lock | any hostile inside scanner range (25 600 units) | estimated from spec §2 / §6 |

## Weapons
| Value | Setting | Source |
| --- | --- | --- |
| laser range | 15 000 units | estimated |
| pulse laser damage | 10 | spec §5 (baseline) |
| beam laser damage | 16 | estimated |
| military laser damage | 24 | estimated |
| shot interval | 0.11 s | estimated |
| energy per pulse shot | 2 | estimated (the original drains the banks as you fire) |
| energy per beam shot | 4 | estimated |
| energy per military shot | 6 | estimated |
| heat per shot | 9 | estimated |
| heat limit | 240 (fire blocked at the limit) | spec §6 |
| heat cooling | 42 per second | estimated |
| missile speed | 900 units/s | estimated |
| missile damage | 120 (one hit kills small fighters) | spec §5 |
| missile lifetime | 9 s | estimated |
| ECM energy cost | 40 | estimated |
| ECM clears missiles | every missile in scanner range | spec §5 |
| energy bomb | one use, destroys every ship in scanner range | spec §5 |
| mining laser splinters | 2 canisters of minerals per asteroid | spec §4 |
| safe zone radius | 6 000 units; firing marks you Offender and launches a Viper | spec §2, §4 |

## Shields / energy / hull
| Value | Setting | Source |
| --- | --- | --- |
| forward shield | 255 | estimated (reference gauge full) |
| aft shield | 255 | estimated |
| shield regen | 2 per second | estimated |
| energy banks | 4 banks, 1020 total | spec §5 "standard 4-bank capacitor array" |
| energy regen | 6 per second (extra energy unit ×1.25 max) | estimated / spec §5 |
| laser damage taken on shields first, then energy | yes | spec §5 |
| enemy hit damage | 7–16 | estimated |
| escape capsule keeps rank, cash and cargo | not fitted at start | spec §5 |

## Ship roster (models in shapes.gd, white wireframes)
| Class | Size | Speed | Energy | Bounty | Source |
| --- | --- | --- | --- | --- | --- |
| Sidewinder | 70 | 370 | 60 | 5 CR | spec §5 roster; numbers estimated |
| Krait | 80 | 300 | 80 | 10 CR | estimated |
| Mamba | 85 | 350 | 90 | 15 CR | estimated |
| Adder | 75 | 240 | 70 | 4 CR | estimated |
| Gecko | 80 | 300 | 75 | 6 CR | spec §5 roster; numbers estimated |
| Cobra Mk I | 65 | 270 | 70 | 8 CR | spec §5 roster; numbers estimated |
| Asp Mk II | 95 | 360 | 120 | 25 CR | spec §5 roster; numbers estimated |
| Fer-de-Lance | 110 | 340 | 140 | 30 CR | spec §5 roster; numbers estimated |
| Python | 150 | 200 | 200 | 20 CR | spec §5 roster; numbers estimated |
| Boa | 180 | 170 | 240 | 25 CR | spec §5 roster; numbers estimated |
| Anaconda | 220 | 150 | 280 | 40 CR | spec §5 roster; numbers estimated |
| Viper (police) | 90 | 320 | 110 | 15 CR | spec §5 roster; numbers estimated |
| Thargoid | 170 | 300 | 260 | 100 CR | spec §5 roster; numbers estimated |
| Thargon drone | 40 | 420 | 18 | 0.5 CR | spec §5 roster; numbers estimated |

Witch-space holds two Thargoids and four Thargon drones; destroying every Thargoid
(Thargons are escorts and need not all die) ends the encounter.

## Scooping / capsules
| Value | Setting | Source |
| --- | --- | --- |
| fuel scoop range | 320 units | estimated |
| sun-skimming refill | 1.4 LY per second inside 1.35× the star's radius | spec §3 ("free alternative to paying for fuel") |
| canister cargo | 1 t of the destroyed ship's goods | spec §3 |
| escape capsule reward | 25 CR | estimated |
| escape capsule price | 1 000 CR, tech 5 | spec §5; price estimated |

## Trading / equipment
| Value | Setting | Source |
| --- | --- | --- |
| commodities | 17 | spec §4 |
| illegal goods | slaves, narcotics, firearms | spec §4 |
| fuel price | 2.0 CR per LY | estimated |
| missile | 30 CR | estimated |
| large cargo bay | 400 CR | estimated |
| rear pulse laser | 400 CR | estimated |
| ECM | 600 CR | estimated |
| beam laser | 1 000 CR | estimated |
| mining laser | 800 CR | estimated |
| fuel scoop | 525 CR | estimated |
| energy bomb | 900 CR | estimated |
| extra energy unit | 1 500 CR | estimated |
| docking computer | 1 500 CR | estimated |
| galactic hyperdrive | 5 000 CR | estimated |
| military laser | 6 000 CR | estimated |
| equipment gated by tech level | yes (1–15) | spec §5 |

## Docking
| Value | Setting | Source |
| --- | --- | --- |
| station spin | 0.12 rad/s about the docking face axis | estimated (reference picture-1 shows the faceted station) |
| docking capture distance | 650 units from station centre | estimated |
| docking requires facing the slot face | forward · face normal < -0.9 | estimated |
| docking requires roll matching | up · slot long axis > 0.86 (within ~30°) | spec §3 "manually match the ship's roll angle" |
| docking speed limit | under 220 units/s | estimated |
| hull collision distance | 470 units | estimated |
| crash damage | 20 + 0.3 × impact speed (20–140), then pushed clear | spec §3 "hitting the exterior hull… causes hull damage" |
| docking computer | aligns roll with the rotating slot and lands automatically (no hull scrapes while it flies) | spec §3 |

## Scoring / rank / law
| Value | Setting | Source |
| --- | --- | --- |
| kill tally | +1 per ship destroyed | spec §6 |
| ranks | Harmless 0, Mostly Harmless 8, Poor 16, Average 32, Above Average 64, Competent 128, Dangerous 512, Deadly 2 560, Elite 6 400 | spec §6 |
| clean → offender | attack a clean ship | spec §1 |
| offender → fugitive | destroy a Viper | spec §1 |
| contraband carried | offender | spec §4 |

## Galaxy
| Value | Setting | Source |
| --- | --- | --- |
| galaxies | 8 × 256 systems | spec §2 |
| generation | deterministic 16-bit seeds | spec §2 |
| hyperspace range | 7.0 LY, 1 fuel per LY | spec §2 |
| witch-space | 8% chance per jump | spec §2 (probability "random") — number estimated |

## Display / controls
| Value | Setting | Source |
| --- | --- | --- |
| screen | 1280×720, black, wireframe, 4-colour HUD (white / yellow / green / red) | reference picture-1, picture-2 |
| viewport / dashboard split | viewport top 77.5%, dashboard bottom 22.5% | measured from reference picture-1 (dashboard begins at row 192 of 248) |
| view name | "Front View" top-centre of the viewport | reference picture-1 |
| planet note | one generated line in the chart panel ("This planet is … for …") from the system seed, our own wording | spec §6 humorous procedural description |
| dashboard | six gauges left (FS, AS, FU, CT, LT, AL), red dashed elliptical scanner centre, speed/roll/climb and four energy banks right, four missile blocks bottom left, green ELITE wordmark bottom centre | reference picture-1 (pixel map: labels x 2–13, bars x 16–47, ellipse rows 204–239, "ELITE" rows 241–245) |
| dashboard columns | left block 0–19% of the width, centre 19–72.5%, right block 72.5–100%; yellow dividers at 19% and 72.5% | measured from reference picture-1 (dividers at x 48 and 184 of 256) |
| gauge bars | 7 rows tiling the dashboard height: 6 gauges + missile row on the left, 7 gauges on the right; bar is 34% of the row height | measured from reference picture-1 (bars 3 px tall in 8 px rows) |
| gauge colour | solid yellow fill from the left, red two-letter label beside it, dashed green tick line under the bar | measured from reference picture-1 (all bars yellow, labels red, tick rows green) |
| canopy edge | alternating white and yellow blocks (4 px each) along the top of the dashboard; solid yellow bottom rail | measured from reference picture-1 (row 192 = WWWWYYYY…, row 247 solid yellow) |
| scanner dish | red dashed ellipse, half-axes 10.9% of the width and 7.1% of the height, centred at 51.6% / 52% of the dashboard | measured from reference picture-1 (ellipse x 104–160, y 204–239) |
| screenshot entry point | `--screenshot <file>` starts a flight with the station ahead and saves after 120 frames, window unfocused | this build (the reference pictures are cockpit views) |
| scanner dish | centre at 50% width, 44% of the dashboard height; half-axes 17% of the screen width and 10.7% of its height | measured from reference picture-2 (ellipse 87 × 41 px) |
| station screens | 7 tabs: buy, sell, equip, galactic chart, local (short-range) chart, status, launch — keys 1–7 or clicks | spec §6 |
| short-range chart | local stars plotted at 1 LY = 4 chart units, yellow ring at the 7.0 LY tank radius, green crosses for systems in current fuel range | spec §6 "7.0 LY fuel radius circle" |
| pitch | S / X or Up / Down | spec §2 controls |
| roll | , / . or Left / Right | spec §2 controls |
| accelerate / decelerate | SPACE / ? | spec §2 |
| fire | A | spec §2 |
| views | 1 2 3 4 or F1–F4 | spec §6 |
| missile lock / fire | T / M | spec §5 |
| E.C.M. | E | spec §5 |
| energy bomb | B (one use) | spec §5 |
| hyperspace | H | spec §2 |
| in-system jump | J | spec §2 |
| docking computer | C | spec §3 |
| galactic hyperdrive | G | spec §2 |

## Not simulated in this build
- Music, and the original's continuous engine/background noise. Short synthesised
  laser, explosion, beep and docking sounds are played.
- The original's pre-flight countdown and launch tunnel animation: launching cuts
  straight to the station exterior.
- Witch-space is escaped by destroying both Thargoids or after 30 seconds; the
  escape capsule cannot be used there.
- Only one commander is stored (auto-saved on docking).
