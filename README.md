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

## On a phone

Under 860px the sidebar stops being a column and becomes a drawer over the page, so the
app opens on the deck you came to read rather than on a list of decks. **Decks**, bottom
left, opens it; picking anything, tapping the dimmed page, or Escape shuts it again. The
drawer always starts shut on a phone — the open/shut preference is saved for the big
screen only, because a drawer gets opened a dozen times an evening and would otherwise
keep overwriting it. Rotating a tablet across the breakpoint hands back whichever state
that size wants.

**Flashcards take a swipe**: left for the next card, right for the one before. A tap
still flips. A drag that is short, or more down than across, is left alone so the page
still scrolls past the card. The keyboard hints (`Space` flip, `←` `→` move) are replaced
by the touch ones wherever there is no mouse — that's the `.kbhint` / `.tiphint` pair, a
media query rather than a device sniff, so a laptop with a touchscreen keeps the keyboard
wording and its small, dense controls.

**Every field is at least 16px on a touch device.** Below that, iOS Safari zooms the page
in when a field takes focus and never zooms back out, which is the single most
maddening thing a web page can do to someone typing an answer. The typed-answer boxes
were already above it; the editor's, the theme boxes and the selects weren't.

The month calendar drops deck names under 560px — a seventh of a phone's width holds
about five letters — and shows a tappable bar instead, with *Next up* underneath carrying
the names. `apple-touch-icon.png` exists because iPhones ignore the manifest's icon and
will otherwise put a screenshot of the page on the home screen. There is deliberately no
`apple-mobile-web-app-capable`: in that mode iOS throws the Google sign-in out to Safari
and the session never comes back.

## Motion

The durations and curves all come from six variables at the top of the stylesheet
(`--ease`, `--t-tap`, `--t-move`, `--t-turn` and friends), so the whole page moves in one
vocabulary: things arriving decelerate, a press answers in 100ms, and the only thing slow
enough to actually watch is a card turning over.

Three facts about this app shape every bit of it, and getting them wrong is how the
animations quietly stopped working before:

- **The stage is rebuilt constantly** — `render()` wipes it for a flipped card and a
  picked answer as much as for a new view. So the page-turn entrance is gated on `FRESH`,
  a signature of view + deck + folder + session mode. Animating every render instead
  makes the page flicker under every tap.
- **A node built already wearing a class has nothing to transition from.** This is why
  the card flip never actually played: flipping re-rendered the stage, and the new card
  arrived already at `rotateX(180deg)`. The card is now kept and only reclassed, with the
  judge buttons underneath as the one part that redraws. The matching grid is kept for
  the same reason — a tile rebuilt wearing `.done` just appeared dim instead of fading
  and shrinking. Where a node genuinely is new each time, like a right or wrong answer
  washing in, it's an `animation`, not a `transition`.
- **A bar rebuilt with the stage has no width to move from**, so `track()` gives it the
  width it had a moment ago and walks it to the new one on the next frame. It only does
  that if it is going to animate; starting at the old value and then not moving would
  leave the bar reading a card behind for the whole session, which is exactly what
  happens on a reduced-motion machine if you forget.

Flashcards arrive from the side you sent the last one out towards, which is what a swipe
has already promised. Grids built only on a view change (the mode tiles, the deck grid,
a folder's list) come in one item at a time; anything a tap inside the view rebuilds must
not, or it flickers on every answer.

Nothing here carries meaning in the movement, so `prefers-reduced-motion: reduce` turns
all of it off with one rule rather than a list — but note that the JS helpers check it
too, via `still()`, because a transition the stylesheet has zeroed still needs the end
value set.

## The mark

The brand kit's index-card mark: a tab behind, the card in front of it, three ruled
lines, the tab in the accent red. The geometry in `icon.svg` was measured straight off
the kit's 192px app icon rather than eyeballed, so it matches to within a pixel.

The palette needed no changes at all — sampling the kit returns `#EFE9DE`, `#FBF8F1`,
`#14110D`, `#151310`, `#1E1A15`, `#EDE6D8`, `#C6BCA8`, `#A8321F` and `#DC7159`, which
are already this stylesheet's `--paper`, `--surface`, `--ink`, `--rule` and `--bad` in
their light and dark forms. The kit was built from the site, not the other way round.

Where it appears:

- **The sidebar**, beside the wordmark, with the byline under it — the kit's horizontal
  lockup. **The welcome page**, above the wordmark at 54px — the stacked one.
- Both are drawn from `var(--ink)`, `var(--surface)` and `var(--bad)` rather than being
  flat images, so the mark follows whichever of the eight themes is on, and a custom
  one too. Checked against each: Blueprint gives it a navy outline and a brick tab,
  Rose its own red, Midnight a cream outline and salmon.
- `icon.svg` for the manifest, `apple-touch-icon.png` (180px, square — iOS rounds it
  itself) and a 32px favicon inline in the head, which drops to two rules because three
  close into a smudge by the time a browser draws it at 16.
- `icon-dark.svg` is the kit's dark lockup, kept as an asset for anywhere that needs one
  on a dark ground. Nothing in the page references it.

## Deck types

A deck is one of four shapes, set by **Type** in the editor.

**Cards** is the plain two-sided card: a term and a definition.

**Vocabulary** adds a part of speech to every word, out of a fixed list of nine. That
unlocks the Parts of speech mode and a third rung in Learn — define it, type it, then
name what it is — so a vocabulary word isn't mastered until all three are done.

**Categories** is that same question with the list of answers moved out of the code and
into the deck. You give the dimension a name (**Called**: Process, Rock type, Device)
and write the buckets yourself, and every card gets filed under one of them. Everything
the part of speech gets, a category gets: its own mode, the third rung in Learn, a
column in the editor, a column in a pasted list, and a share of the questions in a
simulated test. Renaming a bucket rewrites every card already filed under it as you
type, because a card stores the label rather than an id — which is also what lets a
deck move between Vocabulary and Categories without losing what was typed.

**Conjugation** is a grid: one table per verb, with the rows named by you and a tense
across the top. The rows are free text, so it serves any table of forms, not only a
Spanish verb.

## Cards you are having another go at

A flashcard you have got wrong and not got right since is outlined in the accent red
instead of the usual ink, on both faces. It's the same test the **Missed** filter uses
— `wrong > 0` and the last answer wasn't right — so the card says it on itself rather
than only being findable by changing the filter. Marking it **Study again** turns it
red; getting it right turns it back.

**Learn** marks it the same way, on the panel the question is written in. It has to be
the panel rather than the answer box: getting a card wrong in Learn drops it back to
the first rung, so the next time it comes round it is usually a pick-one and there is
no box to outline. When it *is* a typed question, the box is outlined too.

## "I was right" and "I was wrong"

Typing an answer is graded in three bands: exact, near, and no. A near miss is
counted as correct — and only the person who typed it knows whether they actually had
it or were guessing at the shape of the word. So the generous call is theirs to refuse:
a near miss offers **I was wrong**, which takes the mark back, and a wrong one offers
**I was right**, which gives it. Both appear in **Type the answer** and in Learn.

Each undoes the other, so neither is a trap and the score can't drift — pressing them
alternately lands back where it started. In Learn, taking a mark back also gives back
the rung the card was granted and puts it in the queue again, which is the whole point:
a card you only half-knew should come round once more.

All three typed surfaces behave the same way. Review used to be the odd one out: it
graded in the same three bands but only ever said "Correct.", so the one call worth
arguing with was the one it never mentioned — and it moved on by itself after 900ms,
which took the chance to argue with it too. It now names a near miss and holds still
for it. A clean hit still carries you along.

## The dashboard

With editing unlocked, a **Dashboard** button sits in the top right of every page
(`#dashboard` too). It is fixed to the corner rather than put in a header, because
there isn't one — each view draws its own heading row — so every one of those rows is
given a matching gutter. Without it the button lands on top of a view's own buttons at
around 980px wide, which is exactly what it did to the home page's sign-in corner until
`.startbar` and `.testbar` were given the gutter as well. On a phone the label drops and
only the mark is left.

It holds three things:

- **Whether anything is unpublished**, with Publish and Discard right there, and a word
  if this browser has no publishing key.
- **Worth a look** — the standing answer to "have I left anything half-done", which is
  otherwise only visible by opening every deck in turn. Half-written cards, decks with
  no cards at all, decks whose quiz has been and gone and aren't filed away, decks with
  no quiz date, and decks students have sent in. Each row says how many and takes you
  to it; the archive row does the filing itself. Nothing wrong, and it says so.
- **Everything else** — new deck, new folder, announce, calendar, print, submitted,
  people, the publishing key, and the account page.

Submissions are the one count that has to be asked for over the network, so the page is
drawn without it and that row appears only if there turn out to be any.

A student has none of this: the button is hidden, the gutters aren't applied, and
`#dashboard` bounces them home.

## Announcements

**Announce**, in a deck's header when editing is unlocked (or `#notices`), writes a card
that goes up over the page the next time anyone opens the site. Each person sees a given
notice once; dismissing it — the button, Escape, or clicking the dimmed page — remembers
it on that device and it never comes back. Deliberately a pop-up rather than a banner,
because the whole point of these is the things that otherwise get missed.

Give one a **From** date and it waits for the morning it matters. Give it an **Until**
and it takes itself down. **Hidden** parks one without deleting it. The status line under
each says which of those it is doing right now, and **Preview** shows it exactly as a
student gets it without marking anything as read.

They live in their own **`notices.json`**, not in `decks.json`. Decks go through a
careful three-way merge whenever two people publish at once, and a notice has no business
anywhere near that: this way posting one cannot touch a single card, and it doesn't have
to wait for a deck edit to go out. Publishing sends the sha the editor read, so if someone
else wrote in between GitHub refuses it rather than quietly burying their notice. No file
at all is a normal state — it means nobody has written one.

Editing a notice does **not** bring it back for anyone who already dismissed it; they are
remembered by id. To say something again, write a new one.

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

Sign-in is **Continue with Google** or **an email and password**, and it's
optional — without it the app behaves as it always has, keeping scores in the browser.
With it:

- **Scores follow the student**, not the browser. Progress is merged field by field
  (the larger of each count, the higher Learn rung), so studying on a phone and then a
  laptop adds up instead of one overwriting the other.
- **Students can send decks in.** A signed-in student builds a deck and uses **Send to
  the editor** in its editor. It lands under **Submitted**, where the editor approves
  it into their own decks — ready to publish like anything else — or declines it.

### Signing in with an email and password

Under the Google button: an address, a password, **Sign in**, and **Make an account**
to switch the same two boxes into signing up. A new password has to be six characters,
and **Show** reveals what was typed — a typo on the way in is a nuisance, but a typo on
the way *up* locks you out of an account that can't be reset without email.

Supabase's own wording for a wrong password, "Invalid login credentials", is accurate
and no help to a thirteen-year-old, so that one is replaced with a sentence that says
what to do. Everything else it returns is shown as it came.

> **Turn "Confirm email" off in Supabase before a class uses this.**
> Under **Authentication → Providers → Email**. With it *on* — which is how the project
> stands right now — making an account sends a confirmation message first and nobody
> gets in until it arrives, which runs straight into the built-in email sender: a couple
> of messages an hour, and on current projects it only delivers to members of the
> Supabase organisation. With it *off*, signing up returns a session there and then and
> the whole flow sends no email at all. The page handles both, because which one is in
> force is a dashboard setting it can't see.
>
> The trade is that nobody proves they own the address they sign up with. For a study
> app whose rows are scoped per student by row level security, and which holds nothing
> but quiz scores, that is a fair price for not depending on email at all. Decide it
> deliberately rather than by accident.

> **There is no "forgot password".** It would need email, which is the thing being
> avoided. Until SMTP is configured under **Authentication → Emails → SMTP Settings**
> (Resend, SendGrid, Postmark, or the school's own Google Workspace SMTP), a student who
> forgets theirs either makes a second account or has it reset by hand in the Supabase
> table editor. Their scores still work signed out, so this is an annoyance and not a
> catastrophe — but it is the reason the sign-up box says to pick one they'll remember.

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

Eight ready-made, on the **Sign in** page under *Look*: Auto (follows the computer),
Paper, Blueprint, Pine, Rose, Ink, Dusk and Midnight. A theme only swaps the palette —
nothing moves — and is remembered per device. It's applied before the page paints, so
there's no flash of the wrong colour on load.

**Make one** is the ninth. You pick three colours — paper, ink and the highlight used on
the small labels — and the other sixteen variables are worked out from them: surfaces,
the two rule weights, the soft and faint inks, the washes behind green and red. Picking
sixteen colours by hand is not something anyone would finish, and a theme where only
some of them changed would look broken.

The three are stored with the palette they produce, as plain CSS text, so the script at
the top of `<body>` can paint a custom theme before the page draws without the colour
maths having to exist yet. Inline variables on `<html>` outrank every stylesheet rule,
which is why this overrides a theme cleanly and why clearing them hands the page back.

Light or dark is **decided, not chosen**: the paper's luminance picks the direction every
derived colour moves in, and sets `color-scheme` so the browser's own scrollbars and form
controls follow. Pick a dark paper and you get a dark theme without saying so.

Contrast is checked as you type (WCAG, against the paper) and anything under 4.5:1 says
so in red with the actual ratio. It still applies it — being able to see how unreadable
it is beats an argument with a disabled button.

Each theme has a **code** — `fff7e8-23304a-b07a2a`, the three colours — with Copy and
Use code beside it, so one person's theme travels to a friend by text message. Pasting
accepts any separators; a code that doesn't parse is refused and the box goes back to
what it was.

## Two meanings

A word can mean two things — *gall* is nerve and also bitterness; *bank* is the land by a
river and also to rely on something. **+ second meaning** under the definition box opens a
second one. It stays **one card**: asked once, mastered once, counted once. Both meanings
are shown together, numbered, wherever one would have been — the flashcard, the multiple
choice option, the typed prompt, the print-out.

On a vocabulary deck the second meaning gets **its own part of speech**, because that is
the case that needs it. Where the part of speech is the question, **either answer counts**
and both are on the screen, so a student answering about the second meaning isn't marked
wrong for it. The part-of-speech question also prints the numbered meanings under the
word, so it is clear what is being asked about. Getting it wrong says *"it's either an
adjective or a verb"*.

The pair is stored as `def2` and `pos2` next to `def` and `pos`, left out of `decks.json`
entirely when there is no second meaning, so nothing changes for the decks that have one.

**Copy as text** puts both meanings in the one definition column, numbered. Pasting that
back in reads them as a single definition — the paste format is still three columns.

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

## Something's wrong with this card

A flag sits beside every card in **Browse all cards**, and in the bottom corner of a
flipped flashcard. It asks what's wrong and sends the report to the same inbox as
submitted decks, so there is one place to look.

It copies the card's **term and definition into the report**, not just its id, so the
report still reads sensibly after the card has been edited or the deck renamed. The
editor gets **Open the card** — which jumps to that row in the deck editor and puts the
cursor in it — plus **Fixed** and **Dismiss**.

Reporting needs an account: a report nobody can reply to is worth less than no report.
Rather than hiding the flag from signed-out students, it offers them the sign-in. The
flag shows whenever the project answers at all — the sign-in library itself is only
fetched once somebody actually signs in, so gating on the client would have hidden it
from exactly the people it is for.

Needs the `reports` table from `supabase/schema.sql`.

## Pasting a list

**Work it out** is the default, and it does. Per line it finds the divider itself — a
tab, an em or en dash, a hyphen with spaces, a colon, a pipe, a bullet — trying the
unambiguous ones first and a comma last, because definitions are full of commas. Leading
bullets and numbering (`- `, `• `, `1. `, `1) `) are stripped, so a list copied straight
out of a Google Doc imports as it stands.

On a vocabulary deck it also pulls a part of speech off the front of the definition when
one is there: `adamant — adjective — unyielding`, `adamant: (adj.) unyielding` and
`adamant <tab> adj. unyielding` all land in the right three fields. Short forms (`adj`, `n`,
`v`, `prep`) are expanded.

A definition written `1. nerve 2. bitterness` becomes a card with **two meanings**
rather than one definition with numbers in it.

The old fixed separators are still in the menu for a list that needs forcing, and the
preview under the box says what it made of your text before anything is added.

## Duplicating a deck

**Duplicate** in the deck editor copies the whole deck — cards, type, folder,
conjugation rows — under a new name, and opens it. Every id is new, deck and cards
alike, so the two can never be mistaken for each other or merged into one another.

The **quiz date is not copied**. It belonged to the deck you copied from, and a date
that's already passed would file the new deck straight into the archive.

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

## Two editors at once

This used to lose work, quietly. Publishing fetched whatever sha `decks.json` was on and
wrote the whole local store over it, so if somebody else had published while you were
editing, their decks went and nothing on screen said anything had happened.

A publish now compares **three** versions — the decks your draft started from (the
*base*), your draft, and what is in the repo at that second — and works out what each
side did, instead of who happened to go last.

- A field only one side changed takes that side's value. Your rename and their quiz date
  both survive, on the same deck.
- A field you both changed to different things goes to whoever is publishing, and the
  toast names what to go and look at. Changing different cards in one deck is not a
  clash and isn't reported as one.
- Added decks, cards, folders and conjugation forms are kept from both sides. Forms merge
  one cell at a time, so two people can fill in the same verb.
- **Nothing is deleted for being merely absent.** A deck you deleted stays deleted only
  if nobody else edited it in the meantime; if they did, it comes back and you're told.
  That asymmetry is deliberate — a deck wrongly kept is a nuisance, one wrongly deleted
  is somebody's evening.

The base is stored next to the draft in `localStorage`, so this survives closing the
chromebook. A draft saved before this existed has no base; the merge then falls back to a
union, which can only ever add.

While you're editing, the poll that already watches `decks.json` sets the bar to *someone
else published while you were editing* rather than silently moving the ground. If the
repo moves in the seconds between the read and the write, GitHub rejects the write and
the whole thing — re-read, re-merge, re-send — runs again, up to twice.

If the current `decks.json` can't be read or parsed, the publish **stops** instead of
overwriting it.

Every publish is still a commit, so even a merge that goes wrong is recoverable from the
repo's history.

What this does *not* do is show you who else is editing right now. There's nowhere for
that to live yet — Supabase could hold it, but only signed-in editors would appear.

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
