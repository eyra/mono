# Probleem: LiveView heeft geen "middleware" bij mount of events.

Opties:

1. Handmatig check calls uitvoeren
2. Alternatief voor de `live` routing macro maken
3. Macro die standaard LiveView API delegeerd naar custom callbacks


# Handmatig checks uitvoeren

Het voordeel van deze aanpak is dat het relatief simpel is om te maken.

Het grootste nadeel is dat er een risico ontstaat op het vergeten van check
code. Dit kan (ten delen?) ondervangen worden door de Surface Components de
events altijd te laten hashen (daardoor zijn ze niet te gebruiken zonder check)
en custom [linting rules](https://hexdocs.pm/credo/adding_checks.html#content).

# Eigen `live` routing macro

Deze zou dynamisch een module kunnen maken die als een soort proxy werkt. Het
nadeel is dat er waarschijnlijk veel problemen komen (bijvoorbeel bij reverse
route lookups). Ook zijn stack traces etc. minder behulpzaam. Een voordeel zou
wel zijn (mits alles werkt) dat dit relatief transparant gaat. Een live view
heeft dan altijd dezelfde checks.

# Macro die API van LiveView wrapped

Deze zou nieuwe callbacks kunnen definieren die gebruikt moeten worden ipv de
normale. De macro implementeerd de reguliere met de extra authorisatie checks.

Een mogelijk nadeel (wat ook voor specifieke scenario's een voordeel kan zijn)
is dat een live view ook zonder deze macro gemaakt kan worden. In dat geval
zijn er geen checks. Eventueel kan hier iets met linting gedaan worden.



LiveView werkt met Phoenix Channel.
- `handle_event` roept uiteindelijk functie op de live view aan

LiveView mount gaat via router.
