# Revision log

A running record of how the database changed from the Week 2 version, and how
the categories were redefined when the sources didn't fit them. Each entry
names the listing that prompted it. Updated after each issue is finished.

Citations: LC = *Lesbian Connection*; page numbers are the printed page.

---

## 1. Changes to the schema

- **Removed `first_observed_year` / `last_observed_year` from `communities`.**
  They repeated `year_recorded`, could drift out of sync with it, and in the old
  data were computed from all 54 sources. They are now calculated with a query.
- **Added `notes` to `community_observations`.** This separates my judgment calls
  from the listing's own words (`raw_text`), so every inference is visible.
- **Removed `contact_phone` and `contact_email`.** Privacy: they are personal
  details with no historical value. The numbers remain inside `raw_text` because
  the listing is published and is reproduced word for word.
- **Split location into mailing address and land location.** The old
  `contact_*` / `communities` address mixed the two. Dutch Mountain had a Boston
  mailing address for land in Maine, so a query of acreage by state counted
  Maine land as Massachusetts. Now `contact_*` = where the mail goes, `land_*` =
  where the land is, and `land_location_as_stated` keeps vague wording such as
  "southern Oregon".
- **Removed location from `communities`.** It duplicated the observations, and a
  community's location is better recorded per listing.
- **Removed `section` from `sources`; added `page` to `community_observations`.**
  One source row is now one issue, and each listing points to its exact page.
- **Added `focuses` and the junction `observation_focuses`.**
  - Prompted by The Beachtree (LC Dec 1982, p. 22): "Disabled lesbians trying
    to build recreation — independent living for disabled."
  - Accepted groups sort people by sexuality, gender and age only, so the
    community's reason for existing could only be recorded as text.
  - The focus vocabulary covers populations a place centers (disabled, older,
    working-class, in recovery), its politics (separatism), and its purposes
    (spirituality, farming, workshops, archives).
  - Attached to observations, not communities, so focus can change over time.
  - **Added focus 10, Environmentalism/eco-friendly,** for groups that
    declare themselves chemical free: Wisconsin Womyn's Land Co-op's "chemical
    free space" and The Web's "Chemically free" (LC Dec 1982, p. 23).
    - "Chemical free" could be read as drug/alcohol-free, but in these
      listings it goes with land and nature, so it is not coded as recovery.
    - A proposed "healing/health" focus for The Web was rejected; its
      "differently abled" welcome is coded as disabled women instead.
  - **Added focus 11, Women of color/racial diversity.** Lavender Hill (LC
    Dec 1982, p. 23) describes "womyn of diverse ages, races and backgrounds"
    and gives lower fees to "working class/older/third world women". It was
    the first listing to mention race, and the vocabulary had no way to record
    it.
  - **Narrowed focus 11 to "Women of color": explicit invitation or
    recruitment only.**
    - Prompted by Arlene & Arline (LC June/July 1983), who asked that
      visitors be "non-racist, non-classist etc".
    - The broad definition had been coding every statement of inclusiveness
      or anti-racism, which says little about whether a community sought out
      women of color.
    - Removed: Who Farm Inc ("womyn of all ages, races, cultures and
      backgrounds"), Twin Oaks ("strive to eliminate... racism"), and
      Heathcote ("all women of all colours and persuasions").
    - Kept: Owl Farm ("I encourage wimmin of color to come and be here"), and
      Lavender Hill, whose fee exception for "third world women" is a policy
      aimed at drawing women of color to the land.
    - Went from 5 codes to 2. The wording of the removed three is kept in
      `notes`.
  - This gives the database a second many-to-many relationship.
- **Classified ads now count, under a narrow rule.**
  - An ad becomes an observation only if it describes land (or is a land
    community advertising itself) and that place isn't in the same issue's
    directory.
  - Ads for a known community's events or businesses (raft tours, healing
    intensives, North Crow's "Jubilezzie's") are noted on the community.
  - Added so far: Wisconsin Womyn's Land (June/July 1983), Kringle/Wood's
    210-acre dairy farm (June/July 1983), Susan B Anthony Memorial Unrest
    Home's "FEMINIST PIONEERS" ad (Mar/Apr 1983), "240 acres near
    Fayetteville, AR" and the Women Only Ranch (Mar/Apr 1986).
  - The ads in every issue so far were checked, so ads are counted the same
    way in every year.
- **Dropped "NA" from `accepted_groups`.** A listing that names no one now has no
  junction rows. "NA" had counted as a group and inflated the totals.

## 2. How the community types were redefined

- **Type is judged at the time of each listing,** not once per community, so a
  community can change type over time.
- **Living on the land makes it a community, even if the land isn't paid off.**
  Women on Land (LC Sept 1976, p. 13) had "secured" 80 acres and still owed on
  it, but was typed 2, not 5.
- **No land yet, or still negotiating, means type 5 (Land Fund/Seeking Land).**
  - California Women's Land Trust (LC Sept 1976, p. 13): formed "to acquire
    land," no land stated. It is a land trust by name, but not by what it held.
  - Another Demention (LC Sept 1976, p. 13): raising money "to be on the land
    within 30 days."
- **A place that calls itself a retreat is type 4, even when people live there.**
  - Examples: Womanshare (a collective of five), Women's Ways Retreat (two
    permanent residents), and A Woman's Place (a collective and their children),
    all LC Sept 1976, p. 14.
  - *Tension:* the type 4 definition says "rather than year-round residency".
    These places were both homes and retreats.
- **Land one woman bought and hosts is type 3.** Nourishing Space for Women
  (LC Sept 1976, p. 14): "a woman has bought" it "to be used by any woman
  interested."
- **Two women on their own land are type 3, unless they are recruiting a
  community.**
  - Type 3: couples hosting visitors or apprentices. Feathers Farm (LC Dec
    1982), Adlai Neubauer & Karen Hamm (LC Dec 1982), Misty Bottoms Farm (LC
    Mar/Apr 1983).
  - Type 2: two women recruiting "Feminist pioneers... to begin women's rural
    community" (Susan B Anthony Memorial Unrest Home).
  - The line is whether the listing is looking for members.
  - Sharpened in 1986: recruiting makes it type 2 only when the women
    already live on the land. An owner not yet living there stays type 3 even
    when welcoming new members (Duffy Z Baum 1982; Dutch Mountain 1986).
    Applied this way, one woman living on her land who welcomes "new
    members/residents" is type 2 (Chris of Coventree, Deer Song).
- **A bare listing stays untyped.** The Web's 1986 listing is only the "We
  have/are" form. Typing it by default would make a shorter listing look
  like a change in the community, so its type is left blank.
- **Land owned collectively by a wider community is type 2, not 3.** Elwha River
  land (LC Sept 1976, p. 14) was "owned by the gay community of Seattle".
- **Type 4 by function, not only by name.** A vacation ranch "for lesbians
  and gay men on holiday" (North Crow) and educational centers (Who Farm Inc,
  Penthesileia, Inc; LC Dec 1982, p. 24) are gathering spaces, even though
  women live on all three.
- **A new status: inactive.** Who Farm Inc calls itself an "inactive group
  with hopes to revive (trying to get back on our feet)", though women still
  live there. It is neither thriving nor folded. The schema has no status
  column, so this is flagged at the start of `notes`.
- **"Community and retreat": the first-named type wins.** Lavender Hill (LC
  Dec 1982, p. 23) calls itself "a thriving womyn's community and retreat" and
  seeks "permanent members", so it is type 2, not 4. This refines the retreat
  rule for places that call themselves both.
- **Type 3 includes private ownership in progress.**
  - Feathers Farm's 1983 letter says "we don't own Feathers Farm, at least
    not yet". Its 1982 listing had been typed 3.
  - Options considered: retype the 1982 row to 5 (Land Fund), or keep 3.
  - Decision: keep 3. They were in the process of obtaining the land
    privately, and no other type fits.
  - The letter is its own observation, and the 1982 row's `notes` point to
    it. Later evidence adds rows; it doesn't rewrite earlier ones.
- **A squat fits none of the types.** Every type assumes the group owns, rents
  or is buying the land. Ashfield Farm Women (LC Sept 1976, p. 14) were
  "squatting". Typed 2 with an explanation.

- **One type per listing is a limit of the schema.** Many places were both a
  community and a retreat (Lavender Hill, Heathcote, A Woman's Place, Laughing
  Rock, Womanshare in 1986). `type_id` allows one value, so a choice is made
  each time (self-description, first-named, or by function), and the other
  role is recorded in `notes`. A many-to-many type table was considered and
  not adopted.

## 3. How accepted groups are read

- **Lesbians are implied in the questionnaire directories, but only when the
  listing welcomes someone.**
  - LC's 1982 form never lists lesbians under "We welcome:", because the
    whole directory is for lesbians. So Lesbian women is coded by default.
  - Exception: Susan Stone's land (LC Dec 1982, p. 22) welcomes only
    "letters" and seeks "people" to develop the land. With no one named, no
    groups are coded.
- **"Women" or "all women" = Lesbian women + Non-lesbian women.** This is an
  inference, and it is noted every time it is used.
- **Children with no gender given = Girl children + Boy children.**
  - Examples: Sappha Survival School's "one child"; Womanshare's "child care
    is negotiable".
  - The old data had coded some of these as girls only, without evidence.
- **Explicit restrictions override general welcomes.** Women on Land says "We
  will live only with dykes" and "female children only," but also "open to any
  woman who wants to relate to this land." Coded as lesbian women and girl
  children only; the contradiction is kept in `notes`.
- **Listings that never mention lesbians still say "women".** Another Demention
  says only "women". Coded as lesbian and non-lesbian women, with a note. The
  LC editor's introduction to the 1976 directory says some groups "do not
  mention lesbians".
- **Members count as accepted, even when the welcome list leaves them out.**
  - Folly Farm (LC June/July 1983, p. 24) lists "women and men living and
    working on the land", but "males" isn't on its welcome list. The men are
    coded, because they are members.
  - The same line as for residents: members count; tenants (Generous Earth's
    "hets") and visiting friends (Stepping Woods' "male friends") do not.
- **Gay men appear as co-residents,** not just as visitors. On the Elwha River
  land the property was shared with gay men, and "the men here would rather
  turn the total 78 over to the dykes."

## 4. How acreage and residents are counted

- **Acreage counts only land presented as the group's own.**
  - Women's Ways: 10 acres, not the old 100. The other 90 were land it only
    had "access to".
  - This is the same problem as Dancing Fish Lodge's 7,000 "surrounding"
    acres in the old database.
- **When a listing contradicts itself, store the smaller figure.** Lavender
  Hill's text says "160 acres" but its form says "60 acres", and it gives
  "Nine structures" vs. "10". The stored 60 matches the Week 2 README, but it
  is now marked as uncertain.
- **Land funds record the acreage they were trying to get, flagged as not
  held.** Another Demention: 70 acres that "will be available".
- **Residents redefined: members of the land community who live on the
  land,** not everyone living there. This came from Generous Earth Land (LC
  Dec 1982, p. 21): the land was "rented to hets" while "None of the dyke
  collective owners live there now". Counting the renters would misrepresent
  the community.
  - **0** now means no members live there. **Blank** means the listing doesn't
    say. An owned but empty land group is a real state, not missing data.
  - Children of members count (Sappha). Men count when they are part of the
    collective (Elwha River land: 2 lesbians + 3 gay men = 5).
  - **Renters can be part of the community.** Okra Ridge Farm (LC Dec 1982,
    p. 22) lists "two members and two renters". The form counts "4
    lesbians", so the renters are within the lesbian land community, and
    all 4 count. The line is membership in the community, not whether
    someone rents or owns: het tenants (Generous Earth) are outside it,
    lesbian renters (Okra Ridge) are inside it.
- **Questionnaire counts aren't resident counts.** "We have/are: 1 lesbian"
  sometimes describes a landowner who lives elsewhere (Susan Stone, Duffy Z
  Baum, LC Dec 1982). The count is used only when the listing says members live
  on the land.
- **Founders are not current residents.** A Woman's Place was founded by
  "seven women," but the listing doesn't say how many live there now, so the
  count is left blank.
- **Counts can be secondhand and dated.** Sappha's "two women and one child"
  comes from a visitor's account of the previous summer.

## 5. How names and text are handled

- **Names as printed, including unusual spellings.** "Another Demention", not
  the old "Dimension". "Aeneaes Valley Road" and "Port Angles" are kept in the
  addresses as printed.
- **Exception: state codes that are plainly typos are corrected.** Lavender
  Hill's address is printed "Elk, AC 95432". The state fields store CA,
  because a wrong code breaks queries by state; `raw_text` keeps "AC".
- **No invented names.**
  - The old "Four Women's Land (Willits, CA)" became "Four Women", the
    listing's opening words.
  - "Dearest Womyn" turned out to be a letter's greeting, not a name. The
    community is now "Elwha River land", after the river on the property.
- **Other names come only from the listing itself.** Examples: OWLT, SSS, Cave
  Canyon Ranch, Sisters of Diana, Inc.
- **Two listings can be one community.**
  - In LC Mar/Apr 1983 (p. 19), OWL FARM ("two wimmin caretaking OWL") and
    OREGON WOMEN'S LAND TRUST ("in the process of buying OWL FARM") are
    printed separately.
  - They are recorded as two observations of one community (OWLT, community
    1), matching how Wisconsin Womyn's Land Co-op and its DOE Farm were
    handled.
  - This connects OWLT's 1976 listing ("has bought 145 acres") to its 1983
    state ("in the process of buying" 147 acres; "Inactive group with hopes
    to revive").
  - The old data had Owl Farm and OWLT as separate communities.
- **One paragraph can hold two communities.** LAND TRUSTS FOR WOMEN (LC Sept
  1976, p. 13) names two separate trusts, so it became two observations.
- **Verbatim text is read from the page image, not the OCR.** Typos in the
  original are kept ("no woman woman"). `[?]` marks an unreadable character
  (an overtyped phone digit, Women's Ways).
- **The listing's own terms stay in `raw_text`.** The fields I write myself use
  the controlled vocabulary (e.g. "gay men").

## 6. Errors found in the old (Week 2) data

LC Sept 1976: **11 of 12** old rows needed at least one correction.

- **Type changed:** 8 rows (California WLT, Women on Land, Another Demention,
  Four Women, Nourishing Space, Womanshare, A Woman's Place, Elwha River land;
  the retreat rule accounts for several of these).
- **Claims the source doesn't make:** OWLT's description said the land-trust
  effort was "by lesbians"; the listing never says so.
- **Facts from other issues mixed in:**
  - OWLT had "Owl Farm", a Roseburg PO box and "Days Creek", none of which
    appear in this issue.
  - Womanshare had 5 acres and a PO box, also not in this issue.
- **Unsupported acreage:** Womanshare's 5 acres; Women's Ways' 100 acres.
- **Invented names:** "Four Women's Land (Willits, CA)" and "Dearest Womyn".
- **Silently "corrected" spellings:** "Aeneas" and "Dimension".
- **Children coded as girls only, without evidence:** Sappha Survival School.

LC Dec 1982: **28 listings** (plus 2 "folded" mentions).

- **Type changed:** 12 of 28. Feathers Farm, Womonground, Greenhope, Okra
  Ridge, Adlai & Karen, Susan B Anthony Unrest Home, The Web, Rebecca/Susan/
  Anne/Maurine, The Ranch, Who Farm, Rainbow's End, Womanshare.
- **Members counted as residents:**
  - Turtle Land (10), Spiral (14), Yorkville (6) and Rebecca et al. (4) are
    now blank or 0.
  - Susan Stone and Duffy Z Baum (1 each) are now 0; both owners live
    elsewhere.
  - Goldenwimmin went the other way, from 6 to 10: the old draft missed the
    4 children.
- **Names not in the listing:** "Herland" (Duffy Z Baum's land) and "Spiral
  Wimmin's Land Trust" (Spiral). Both were probably taken from later issues.
- **Men coded as "NA"** instead of gay/non-gay men: Adlai & Karen, Jan F Walsh,
  Twin Oaks, Far Away Farm.
- **Children missing:** Feathers Farm ("women and children").
- **Groups without land included:** Ellie's Nest, River Most Wild, Aradia,
  Women's Wilderness Experience. All are now excluded. (The old data also
  included Pagoda, which is now included again, as a lesbian residential
  community.)

LC Mar/Apr 1983: **12 listings** (Owl Farm and OWLT count as two), plus the
Ozark end-of-land mention and the Feathers Farm letter.

- **Type changed:** 6 of 12. Rowdybush Farm (4→2), Earth Current Farm (3→2),
  Cedar (5→2), Fly Away Home (3→2), Rootworks (4→3), Owl Farm (2→1).
- **Names not in the listing:**
  - "Laughing Rock Farm/Wise Woman Center" (Rowdybush Farm) and "Earth
    Current Womens Hermitage" (Earth Current Farm), probably from later
    issues.
  - Spellings run together: "Mistybottoms", "Flyaway Home",
    "Steppingwoods".
- **Residents:** Northwoods stored the middle of "6-10" (8), now the
  minimum (6). Earth Current Farm counted all 6 members, but the listing says
  "4 on the land".
- **Owl Farm and OWLT were split** into two communities, with OWLT's 1976
  row unconnected to its land.
- **Groups without land included:** Gabriel's, Sea Gnomes Home.
- **Month:** the old row had "March"; the cover says "March/April 1983".

LC June/July 1983: **14 directory listings** (including the Northwoods
addendum), plus the Lavender Hill sale and two classified-ad observations.

- **Type changed:** 4. Northwoods (4→2), Heathcote (2→1, "in a land trust"),
  Moon Ridge (3→2), D W Outpost (5→2).
- **Names from later issues:** "Dutch Mountain" (Reggie Odom & Eileen
  Kennedy's land), "Gathering Ground" (Linda Tisdale/Carol Shoreborn's land),
  and probably "Greenstalk" for the listing headed "WE DON'T HAVE A NAME YET".
  Spellings run together: "Moonridge", "D.W. Outpost".
- **Residents:** Reggie & Eileen counted as 2, though they were "currently
  living in city".
- **Included a rental cabin** (Pepperland); **missed** the ads.

LC Mar/Apr 1986: **29 directory listings** (one bare listing left untyped),
plus two classified-ad observations. 25 communities now appear in more than
one issue.

- **Type changed:** 10. Feathers Farm (4→2), Chris of Coventree (3→2), Deer
  Song (3→2), Laughing Rock (4→2), Herland (3→2), Susan B Anthony (3→2), Maple
  Row (3→2), The Web (3→untyped), Penthesileia (3→2), Rootworks (3→2). Most
  follow the rule that women living on the land who recruit members are
  type 2.
- **Members counted as residents:** Spiral (33 members → blank, since
  "Supportive Membership" does not involve living there); Silver Circle
  (4 → 2, "two wimmin living on the land and two... in different cities").
- **Names from other issues applied backward:** "Herland", "Dutch Mountain",
  "Gathering Ground", "Greenstalk", "Laughing Rock Farm", "Earth Current
  Womens Hermitage" and "Spiral Wimmin's Land Trust" were used for earlier
  listings that didn't have them. Now each observation keeps its own name in
  `raw_text`, and the community takes the latest name.
- **Guest houses without land included:** Sea Gnomes' Home, Half Moon Pines.

## 7. Excluded listings

LC Dec 1982, under the editor's note "These groups don't have land, per se,
but we wanted to include them for your information" (pp. 24–25):

- Ellie's Nest (Key West, FL): a guest house "for and by women"
- River Most Wild (Ridge Manor, FL): one woman's house with guest rooms
- Aradia Inc Marie Curie Task Force (Grand Rapids, MI): members own land "as
  individuals and severals", not as a group; "inactive group with hopes to
  revive"
- Women's Wilderness Experience (Santa Fe, NM): a backpacking organization
- Lesbians on Land (Joyce Cheney, Burlington, VT): a call for stories of
  lesbian lands for a book (probably Cheney's later *Lesbian Land*; verify
  before citing)

LC Mar/Apr 1983, under the editors' note "These groups don't have land,
perse, but we decided to include them for your information" (p. 19):

- Gabriel's (Provincetown, MA): a women's guesthouse
- Sea Gnomes Home (Stonington, ME): a womyn's rooming/guest house

LC June/July 1983, under "These groups don't have land, per se, or they
aren't exactly land groups" (p. 24):

- Pepperland (Albion, CA): a single rental cabin on 2 acres
- (Wilderness Way, under the same note, was *included*: it's a women's
  campground on its own 10 acres, like North Crow Vacation Ranch.)

Classified ads excluded (all issues checked):

- Dec 1982: "TWO WOMEN (30,35)... seeking to JOIN or FORM" women's land (no
  land); "45-105 ACRES SOUTH VERMONT: Sell, lease, trade for West Coast
  property, may donate part for women's use" (property for sale, not a group)
- June/July 1983: "SEPARATISTS: wanting to form a lesbian country
  community" (no land); "VACATION: at a chemical free lake cottage in
  Wisconsin" (rental cottage); "LESBIAN SELF-SUFFICIENCY WEEKENDS" (no land)

Also *included* after reconsideration: The Pagoda Community (Dec 1982), first
excluded under the "don't have land, per se" note. It was reconsidered when it
reappeared in 1986 as "a small lesbian residential community" where "Only
lesbians can rent or own". It is now recorded in both years.

LC Mar/Apr 1986, in the "GUEST HOUSES/RETREATS/ETC" section (p. 11):

- Sea Gnomes' Home (Stonington, ME): "Womyn's Guest House offering 3 rooms"
- Half Moon Pines (Hamburg, PA): "Vacation cabin in the Blue Mountains"
- (Laurel Ridge, Labrys and River Spirit Retreat, in the same section, were
  *included*: all are women's guest houses, resorts or retreats on their own
  land. Pagoda was included as a lesbian residential community.)

Classified ads excluded, LC Mar/Apr 1986: guest houses and B&Bs (Blueberry
Ridge, a Eugene B&B, a rental room in Hinton, WV); events (Sources retreat
weekends, Campfest '86, the Southern Women's Music & Comedy Festival, a
feminist girls' camp); "COASTAL SISTERS" (seeking a community); and land for
sale (Spiral's bordering acreage, and J Haggard's Minnesota land, both noted
on their communities).

Printed under the same note, but *included*: Ozark Wimmin's Land Trust. It
had land, and the land was dissolved ("The pieces of land wound up in legal
dissolution eventually"). It is recorded as an end-of-land mention.
