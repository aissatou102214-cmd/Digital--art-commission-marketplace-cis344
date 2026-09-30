# Process Documentation — Digital Art Commission Marketplace

## 1. Mini World Selection
I chose the **Digital Art Commission Marketplace** from the professor's Mini World list. It fits the project scope because it has several entity types. It has a central entity (Commission) with one-to-many relationships, a many-to-many relationship (commissions and categories) as well as a one-to-one style relationship (one review per commission). That is enough variety to practice the ER concepts from chapters 3 and 4 without being too large to finish.

## 2. Purpose
Artists and clients often arrange commissions through scattered direct messages, with prices, files and payments tracked in different places. The purpose of this system is to centralize the whole workflow (discovery, request, negotiation, payment, delivery and review) in one database. This makes requests, files, payments and feedback organized and easy to look up.

## 3. Real-World Workflow
1. An artist registers and creates an artist profile.
2. The artist adds portfolio items and lists commission types with prices.
3. A client registers, browses artists and submits a commission request with a title, brief, budget, and deadline.
4. The artist accepts or declines and the commission status changes.
5. Client and artist exchange messages and artwork versions (sketch, revision, final).
6. Payments (for example a deposit and a final payment) are recorded.
7. The commission is marked completed and the client leaves one review.

## 4. How Requirements Were Determined
I determined the requirements by:
- Working through the workflow above step by step and listing the data each step needs.
- Applying the entity, attribute and relationship concepts from course chapters 3 and 4.
- I determined the requirements by working through the commission workflow step by step and listing the data each step needs. I then applied the entity, attribute and relationship concepts from course chapters 3 and 4. I did not conduct interviews or surveys.

## 5. Functional Requirements
- FR1: Users register with a role: client, artist, or admin.
- FR2: Artists have a profile, portfolio items, and commission types with prices.
- FR3: Clients have a profile and can submit commission requests.
- FR4: A commission records title, brief, budget, deadline, and status.
- FR5: A commission can belong to several categories.
- FR6: Messages are attached to a commission and sent by a user.
- FR7: Artwork files are versioned and attached to a commission.
- FR8: Payments are recorded per commission; a commission can have several.
- FR9: A commission can have at most one review, with a 1–5 rating.
- FR10: An artist's average rating is updated when a review is added.

## 6. Non-Functional Requirements
- Use MySQL with InnoDB so foreign keys are enforced.
- Store passwords as hashes, not plain text.
- Use timestamps on key tables for auditability.
- Use constraints (PK, FK, UNIQUE, CHECK) to protect data integrity.
- Use a clear normalized structure that is easy to maintain and extend.

## 7. Design Decisions
| Decision | Reason |
|---|---|
| Separate ArtistProfiles and ClientProfiles | Role-specific columns differ; avoids many NULL columns in Users |
| UNIQUE on `user_id` in each profile table | Enforces 1 User : 0..1 profile |
| Commissions is the central entity | Messages, artwork, payments, categories and review all hang off it |
| Bridge table CommissionCategories | Resolves the many-to-many between Commissions and Categories |
| UNIQUE on `Reviews.commission_id` | Enforces at most one review per commission |
| Separate Payments table | Deposits and final payments tracked individually |
| UNIQUE (commission_id, version) on Artworks | Prevents two files with the same version number for one commission |
| CHECK constraints (rating 1–5, positive amounts) | Blocks invalid data at the database level |
| Trigger for `rating_avg` | Keeps a derived value consistent without manual updates |

## 8. Assumptions and Limitations
- Actual file storage and payment processing are outside the database; only URLs and transaction references are stored.
- The database does not enforce that the reviewer is the commission's client; an application layer would check that.
- The `rating_avg` trigger runs on review inserts only; updates or deletes of reviews would need extra triggers.
