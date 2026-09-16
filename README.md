# Quizletish

A study site for course terms — an adaptive Learn mode, flashcards, multiple choice,
typed recall, and a timed matching drill, with decks organised into folders. Static: no build step, no server, no database. It runs on GitHub Pages
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

## Folders

Folders group decks in the sidebar. They start collapsed, except the one holding the
deck you're on, and remember being opened or closed. Clicking a folder's name opens a
page listing its decks with each one's Learn progress.

As the editor: **Folder** in the sidebar makes one; rename it on its page. Move a deck
in or out with the folder menu under its name in the deck editor, which can also make a
new folder on the spot. Deleting a folder never deletes decks — they move out to the
main list. Folder changes publish like any other edit.

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
4. Generate, copy, paste it into the app.

Scoped that way the token can change **one file in one repo** and nothing else. It's
stored in that browser and never written into the site's code, so it isn't in this repo
and students never see it. Treat it like a signed-in session: don't set it up on a
shared machine, and use **Disconnect** if you ever do. If it leaks, revoke it at
`github.com/settings/tokens` — nothing else needs changing.

### Editing by hand

You can still edit `decks.json` directly and push; the app picks up either. The shape:

```json
{
  "version": 1,
  "updated": "2026-09-16",
  "folders": [
    { "id": "f1", "name": "Week 3" }
  ],
  "decks": [
    {
      "id": "d1",
      "name": "First Amendment Basics",
      "subject": "Con Law II",
      "folder": "f1",
      "createdAt": 1000,
      "cards": [
        { "id": "c1", "term": "Prior restraint", "def": "Government action barring speech before it occurs." }
      ]
    }
  ]
}
```

Every `id` needs to be unique and should stay stable — student progress and stars are
filed against the card id, so renaming an id resets that card for everyone. `folders`
and a deck's `folder` are both optional — leave `folder` off and the deck sits outside any
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
