# Quizletish

A study site for course terms — an adaptive Learn mode, flashcards, multiple choice,
typed recall, and a timed matching drill, with decks organised into folders. Decks come
in three types: plain cards, vocabulary (each word carries a part of speech), and
conjugation (each verb carries a table of forms). Static: no build step, no server, no database. It runs on GitHub Pages
straight out of this repo.

**Live:** https://quizletish.catherine-crump.com — served from this repo by GitHub Pages
(the `CNAME` file is what points the domain here; don't delete it).

## The two files that matter

| File | What it is |
| --- | --- |
| `index.html` | The whole app — markup, styles, and script in one file. |
| `decks.json` | Every deck and card. This is the shared content. |

`.nojekyll` just tells GitHub Pages to serve the files as-is.

## Learn

The main study mode, modelled on Quizlet's. It runs in rounds of seven, and every card
climbs two rungs:

1. **Multiple choice.** Pick the right answer out of four drawn from the same deck.
2. **Typed.** See the definition, type the term. Spelling slips still count.

A card is **mastered** only after both. Miss either one and the card drops back to the
start *and* comes back again later in the same round, so the right answer is seen while
it's fresh. Rounds favour cards already half-learned, but always leave room to bring in
new ones.

The typed rung always asks for the term, whichever direction the deck is set to. Typing
a whole definition back word for word is a transcription test, and definitions that
start with a part of speech ("noun …") would mark a correct answer wrong.

Learn progress is saved after every answer, per student name, in that browser — leaving
mid-round loses nothing. The deck page's **Mastered** count is Learn's.

## Home

The wordmark in the sidebar goes home. Someone who has never been here gets a short
welcome explaining what the site is, with **Sign in** in the corner; everyone else gets
a dashboard — what's due with countdowns, a Review button, how much of everything is
mastered, and every deck as a card.

Arriving at the bare address lands on home, **unless you were studying a deck within the
last twelve hours**, in which case it reopens that. A shared `#deck=` link always wins
over both.

## Links, review, offline

**Links.** Every deck has one: the **Link** button on a deck copies
`…/#deck=<id>`, which opens straight into it — handy for "study this before Tuesday".
`#folder=<id>`, `#cal` and `#review` work too, a folder or deck name works in place of
the id, and the back button behaves.

**Review** gathers the shaky cards from *every* deck instead of one at a time, which is
what you actually want the night before three quizzes. It ranks by how wrong you've been
and how close the quiz is: a card you got wrong and haven't fixed outranks one you merely
started, and anything with a quiz in the next two days jumps the queue. Each question
says which deck it came from. It's in the sidebar under *Coming up*, with a count.

**Offline.** The site keeps a copy of itself and of `decks.json`, so it still opens on a
chromebook with no wifi, and can be added to a home screen. Both are fetched from the
network **first** — the cached copy is only the fallback — so a publish is never hidden
behind a stale cache. The Supabase and GitHub calls are never cached, so a failed save
stays a visible failure rather than a fake success. If it ever misbehaves, add `?nosw`
to the address to tear it down.

## Who can do what

Three levels, set under **People** (owners only):

- **Student** — study, and send decks in.
- **Editor** — that, plus edit the decks, publish, and judge submissions.
- **Owner** — that, plus decide who is what.

Access can be given to someone who **has never signed in**: their profile doesn't exist
until they do, so the email address is parked in `invites` and applied automatically the
first time they arrive. Take it back any time before that.

Only an owner can change a level, enforced by a database trigger rather than by hiding
buttons — an editor who went looking for the API would still be refused. Stepping
yourself down from owner asks first, since it's one-way if you're the only one.

The first owner has to be set in the Supabase table editor, the same bootstrap problem
every system of this kind has.

## Accounts

Sign-in is **Continue with Google**, and it's optional — without it the app behaves as
it always has, keeping scores in the browser. With it:

- **Scores follow the student**, not the browser. Progress is merged field by field
  (the larger of each count, the higher Learn rung), so studying on a phone and then a
  laptop adds up instead of one overwriting the other.
- **Students can send decks in.** A signed-in student builds a deck and uses **Send to
  the editor** in its editor. It lands under **Submitted**, where the editor approves
  it into their own decks — ready to publish like anything else — or declines it.

The backend is Supabase (free tier). Its URL and **publishable** key are in `index.html`
and are meant to be public; the secret key is not used anywhere and must never be. What
actually protects the data is row level security, set up by `supabase/schema.sql`:

- A student can read and write **only their own** progress. The editor cannot read it.
- A student can send submissions and see **their own**; the editor sees all of them and
  is the only one who can change their status.
- `is_editor` cannot be set from the app. A trigger blocks it — flip it in the Supabase
  table editor.

Signing in brings your Google profile picture with it — it shows in the sidebar, on your
account, and beside any deck a student sends in, so the editor can see who sent what.

An editor account **unlocks the card editor on its own**, so the ADMIN password isn't
needed any more and its box is gone from the sign-in page. That check is made by the
database rather than by JavaScript anyone can read, which makes it the first real lock
the app has had.

The password still works, as a way back in if the account route ever fails — the project
being unreachable, or an account that hasn't been given the editor flag. Add `#editor`
to the site's address and the box reappears. It shows on its own if the sign-in service
can't be reached at all.

**Publishing still needs the GitHub token** — the decks live in `decks.json` in this repo,
and only a GitHub credential can write there; being an editor in Supabase grants nothing
on GitHub. But you only paste it once: signed in as the editor, the key is kept against
your account in `editor_keys` and comes back on any computer you sign into. That row is
readable only by the person it belongs to — there is deliberately no editor policy on it,
so not even another editor could read someone else's. Disconnect forgets it everywhere.

Signed out, it falls back to the old behaviour: the browser alone, plus whatever your
password manager saved.

Setting it up from scratch: run `supabase/schema.sql` in the SQL editor, set your own
row's `is_editor` to true under **profiles**, then add the site URL under
**Authentication → URL Configuration** or sign-in links will bounce. Google sign-in needs
the Google provider switched on in Supabase; until it is, the app offers only the
email-link option, and shows nothing at all if the project can't be reached.

## Quiz dates

Give a deck a **Quiz** date in its editor and the rest follows:

- **Coming up** in the sidebar lists the next four, counting down ("today", "in 3d").
- Decks **sort by soonest first** everywhere, with undated ones last.
- A **Calendar** page (the icon next to *Coming up*) shows the month with each quiz on its
  day, and a "Next up" list underneath. Click any of it to go study that deck.
- When a quiz date passes, the deck **moves itself into an Old folder**. This only runs
  when you're signed in as the editor, because it's a change to the shared file and has
  to be published like any other — a student's browser never rearranges anything. Tick
  **Use as the Old folder** on any folder's page to choose where they go; otherwise one
  called "Old" is made the first time it's needed.

## Simulated test

**Simulated test** on any deck builds a timed run-through: pick how many questions, a
time limit, and which question types to mix (multiple choice, typing, and part of speech
on a vocabulary deck). If the deck is in a folder you can cover the whole folder instead
of one deck, which is what makes it useful for an end-of-unit review.

It scores at the end and lists **every question** with what you put beside the right
answer. The clock turns red in the last 30 seconds and hands the test in by itself when
it runs out.

## Print

**Print** on a deck, or on a folder page, lays the cards out as a plain list — term,
part of speech if it has one, definition — and strips the interface out of the printed
page. A conjugation deck prints one line per form.

## Themes

Eight of them, on the **Sign in** page under *Look*: Auto (follows the computer), Paper,
Blueprint, Pine, Rose, Ink, Dusk and Midnight. A theme only swaps the palette — nothing
moves — and is remembered per device. It's applied before the page paints, so there's no
flash of the wrong colour on load.

## Deck types

Set this with the **Type** menu in the deck editor. It changes what you can type in and
which study modes appear; switching type never throws data away.

**Cards** — the original two-sided card. Term on one side, definition on the other.

**Vocabulary** — adds a part of speech to each word, picked from a fixed list so it stays
consistent. In Learn the word climbs a third rung: pick the definition, type the word,
then name what part of speech it is. All three, and only then is it mastered. Words left
without a part of speech master after the usual two rungs. There is also a **Parts of
speech** mode that drills only that, start to finish.

The options offered are only the parts of speech **this deck actually uses** — a deck of
nouns, verbs and adjectives never offers "preposition" — so the choices stay plausible
and the deck sets its own difficulty. A deck using only one part of speech has nothing to
tell apart, so the question is dropped: the mode is greyed out and Learn goes back to two
rungs.

**Conjugation** — one verb per card, with a table of forms. The deck sets the tense and
the rows (yo, tú, él/ella/usted, nosotros, vosotros, ellos/ellas/ustedes by default;
rename or delete rows, or add your own, for another language). Each card holds the verb,
its meaning, and one form per row.

A verb deck can be drilled two ways, chosen with the **Conjugation / Meaning** switch
above the modes: *Conjugation* drills the forms, *Meaning* drills what the verbs mean
(`recordar → to remember`), using the meaning on each card. The two keep separate
progress, because they are separate things to know.

In Conjugation it is studied two ways:

- **Fill the table** — one verb at a time. Type every form, then the table is marked row
  by row, with the right answer shown beside anything missed.
- Everything else — Learn, flashcards, multiple choice, typing, matching — drills the
  forms **one at a time** ("recordar · nosotros" → "recordamos"). The wrong options in
  multiple choice are other forms from the same deck, so they are genuinely hard. The
  Term → Definition toggle disappears, since a form is only ever asked the one way.

Typed answers forgive spelling slips here as everywhere, so a missed accent on
`probáis` still counts.

### Pasting a list into them

**Paste a list** follows the deck's type, one line per card:

```
Cards         term <tab> definition
Vocabulary    word <tab> part of speech <tab> definition
Conjugation   verb <tab> meaning <tab> yo, tú, él, nosotros, vosotros, ellos
```

For vocabulary, leave the middle field out and the part of speech stays blank. For
conjugation the forms can each be their own column instead of one comma-separated list.
**Copy as text** gives the same columns back.

## Folders

Folders group decks in the sidebar, and can hold subfolders up to three levels deep
(say, unit › week › topic). They start collapsed, except the ones leading to the deck
you're on, and remember being opened or closed. A folder's count includes everything in
its subfolders. Clicking a folder's name opens a page listing its subfolders and decks
with Learn progress for each.

As the editor:

- **Folder** in the sidebar makes a top-level folder; **New subfolder** on a folder's
  page makes one inside it. Rename a folder on its page.
- Move a **deck** with the **Folder** menu under its name in the deck editor.
- Move a **folder** with the **Inside** menu under its name on its page. It only offers
  places the folder can actually go — never inside itself, and never deep enough to
  push its own subfolders past three levels.
- Deleting a folder never deletes what's in it: its decks and subfolders move up one
  level.

Folder changes publish like any other edit.

## Adding cards

Open the site, click the bar at the bottom of the deck list, and unlock the editor under
*Course editor*. Add decks and cards, or use **Paste a list** to dump in a spreadsheet
column pair at once. Edits are held in your own browser and flagged *Unpublished
changes* until you hit **Publish to everyone**.

Publish writes `decks.json` to this repo over the GitHub API and commits it for you.
Students see it once Pages rebuilds — usually under a minute — and tabs already open
pick it up on their own without a reload.

### One-time setup for publishing

Publishing needs a token, because writing to the repo means being you. The app walks you
through it under **Set up publishing**; the short version:

1. Go to `github.com/settings/personal-access-tokens/new` — the **fine-grained** token
   page, not the classic one.
2. Resource owner `homejeopardy`. Under **Repository access** pick **Only select
   repositories** → `recall-desk`.
3. Under **Repository permissions** set **Contents** to **Read and write**. Leave
   everything else alone.
4. Under **Expiration** pick **No expiration**, or the longest it offers. The box
   defaults to **30 days**, which is the usual reason publishing quietly stops working a
   month later.
5. Generate, copy, paste it into the app.

**Say yes when the browser offers to save it.** The setup box is a real sign-in form, so
your password manager (iCloud Keychain, Chrome, 1Password…) keeps the token and fills it
in next time — including on your other devices, which is the only thing that carries it
from one browser to another. The app also asks the browser for persistent storage, which
Chrome, Edge and Firefox grant to a site you use regularly. Safari clears script-written
storage after about a week of not visiting the site, so there the password manager is
what saves you.

**Connected** shows the date the token was saved and has a **Check it still works**
button that asks GitHub. A token that has expired or been revoked is named as such and
cleared, rather than left sitting there dead — and an unpublished draft survives either
way, so nothing is lost when it happens mid-edit.

Scoped that way the token can change **one file in one repo** and nothing else. It's
stored in that browser and never written into the site's code, so it isn't in this repo
and students never see it. Treat it like a signed-in session: don't set it up on a
shared machine, and use **Disconnect** if you ever do. If it leaks, revoke it at
`github.com/settings/tokens` — nothing else needs changing.

### Editing by hand

You can still edit `decks.json` directly and push; the app picks up either. The shape:

A vocabulary deck adds `"kind": "vocab"` and a `pos` per card. A conjugation deck adds
`"kind": "conj"`, a `tense`, a `persons` list, and a `forms` map per card keyed by person
id:

```json
{
  "kind": "conj",
  "tense": "Present",
  "persons": [{ "id": "yo", "label": "yo" }, { "id": "tu", "label": "tú" }],
  "cards": [
    { "id": "c1", "term": "recordar", "def": "to remember",
      "forms": { "yo": "recuerdo", "tu": "recuerdas" } }
  ]
}
```

The plain-card shape, unchanged:

```json
{
  "version": 1,
  "updated": "2026-09-16",
  "folders": [
    { "id": "f1", "name": "Unit 1" },
    { "id": "f2", "name": "Week 3", "parent": "f1" }
  ],
  "decks": [
    {
      "id": "d1",
      "name": "First Amendment Basics",
      "subject": "Con Law II",
      "folder": "f2",
      "createdAt": 1000,
      "cards": [
        { "id": "c1", "term": "Prior restraint", "def": "Government action barring speech before it occurs." }
      ]
    }
  ]
}
```

Every `id` needs to be unique and should stay stable — student progress and stars are
filed against the card id, so renaming an id resets that card for everyone. `folders`, a
folder's `parent`, a deck's `folder`, `kind`, `tense` and `persons`, and a card's `pos`
and `forms` are all optional — leave `folder` off and the deck sits outside any
folder, and a `folder` that doesn't match a listed id is ignored. `createdAt` only sets
the order decks appear in the rail. In a definition, alternate accepted
answers can be separated with `/`; typed answers also forgive spelling slips.

If you edit both by hand and in the browser, the browser publishes whatever it has and
the app will tell you when the file changed underneath it. Reload before a big edit.

## Who can actually change the cards

Two separate things, worth keeping straight:

**The `ADMIN` password unlocks the editor UI, and that's all it does.** This is a public
repo and the check runs in the browser, so a determined student can read `index.html`,
find the hash, and turn the editor on for themselves. It's a mode switch, not a lock.

**The token is what publishes**, and it isn't in the code — it's in your browser. So a
student who gets past the password can rearrange their own copy and nothing more. That
separation is the real protection. Don't reuse a password here that you use elsewhere.

To change the password, hash the new one and replace `ADMIN_HASH` in `index.html`:

```bash
node -e "console.log(require('crypto').createHash('sha256').update('recalldesk.v1.'+process.argv[1]).digest('hex'))" 'your-new-password'
```

## Student scores

Signing in as a student is a name, nothing more — it files scores under that name in
that browser's `localStorage`, so two people on one classroom laptop stay separate.
Scores never leave the device and never reach you or the repo. Clearing site data or
switching to another computer starts them over. Cross-device progress would need
accounts on a server, which this deliberately doesn't have.

## Running it locally

`decks.json` is fetched, so opening `index.html` from the Finder won't work — it needs
to be served:

```bash
python3 -m http.server 4173
```

Then open http://localhost:4173.
