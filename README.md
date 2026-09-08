# Recall Desk

A study site for course terms — flashcards, multiple choice, typed recall, and a timed
matching drill. Static: no build step, no server, no database. It runs on GitHub Pages
straight out of this repo.

**Live:** https://homejeopardy.github.io/recall-desk/

## The two files that matter

| File | What it is |
| --- | --- |
| `index.html` | The whole app — markup, styles, and script in one file. |
| `decks.json` | Every deck and card. This is the shared content. |

`.nojekyll` just tells GitHub Pages to serve the files as-is.

## Adding or changing cards

Two routes to the same place. Either way, **students see the change only once the new
`decks.json` is committed** — that commit is what publishing means here.

**In the browser (easier).** Open the site, click the bar at the bottom of the deck
list, and unlock the editor under *Course editor* with the username and password. Add
decks and cards, or use **Paste a list** to dump in a spreadsheet column pair at once.
Your edits are held in your own browser and marked *Unpublished changes*. When you're
done, hit **Download decks.json**, drop the file over the one in this repo, and commit:

```bash
git add decks.json && git commit -m "Update decks" && git push
```

**By hand.** Edit `decks.json` directly and push. The shape:

```json
{
  "version": 1,
  "updated": "2026-09-07",
  "decks": [
    {
      "id": "d1",
      "name": "First Amendment Basics",
      "subject": "Con Law II",
      "createdAt": 1000,
      "cards": [
        { "id": "c1", "term": "Prior restraint", "def": "Government action barring speech before it occurs." }
      ]
    }
  ]
}
```

Every `id` needs to be unique and should stay stable — student progress and stars are
filed against the card id, so renaming an id resets that card for everyone. `createdAt`
only sets the order decks appear in the rail. In a definition, alternate accepted
answers can be separated with `/`; typed answers also forgive spelling slips.

## What the editor password does, and what it doesn't

The password gate is a **mode switch, not security**. This is a public repo and the
check runs in JavaScript in the browser, so anyone determined enough can read
`index.html`, find the hash, and turn the editor on for themselves. That was a known
trade of going fully static — a real check needs a server.

It matters less than it sounds, because **unlocking the editor doesn't let anyone change
what other people see.** Edits live in that one browser until someone with push access
commits a new `decks.json`. The worst a student can do is rearrange their own copy.

Never reuse a password here that you use anywhere else.

To change it, hash the new one and replace `ADMIN_HASH` in `index.html`:

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
