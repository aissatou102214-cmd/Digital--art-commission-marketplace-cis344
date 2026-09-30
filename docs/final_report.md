# Final Project Report — Digital Art Commission Marketplace
Aissatou Barry
Lehman College
CIS 344, Fall 2026
Prof. Yanilda Peralta Ramos
September 29, 2026

## 1. Introduction and Scope
This project builds a relational database for a Digital Art Commission Marketplace, covering user accounts, artist and client profiles, portfolios, commission types and requests, categories, messages, artwork versions, payments, and reviews. It covers the data layer only; a user interface is outside the scope.

## 2. Requirements and Design Process
I started by writing out the real-world workflow (artist sets up a profile, client requests a commission, artist accepts, they exchange messages and files, payment is recorded and a review is left). From each step I listed the data needed and grouped it into entities. I then identified relationships and cardinalities using the chapter 3 and 4 concepts. The detailed requirements and the way I determined them are in the process documentation.

Steps followed:
1. Chose the mini world.
2. Documented the workflow and requirements.
3. Drew the Chen-style ER diagram by hand.
4. Built the EER (UML-style) model in MySQL Workbench.
5. Wrote and tested the SQL script.
6. Saved the `.mwb` file and organized the GitHub repository.

## 3. Database Structure
The database has 11 entities plus one bridge table and 14 foreign keys.

- **Users** holds all accounts. **ArtistProfiles** and **ClientProfiles** each link to one user through a unique foreign key.
- **Commissions** is the central table. It references one client and one artist.
- **Categories** and **CommissionCategories** implement a many-to-many relationship.
- **Artworks**, **Payments**, and **Messages** are one-to-many children of Commissions.
- **Reviews** has a unique `commission_id`, so a commission has at most one review.
- **PortfolioItems** and **CommissionTypes** are one-to-many children of ArtistProfiles.

Extra structures: three indexes, one trigger (`trg_reviews_after_insert`) that updates the artist's average rating, and one view (`vw_commission_overview`) that summarizes each commission with client, artist, and total paid.

## 4. Design Decisions
- Separate profile tables avoid nullable role-specific columns in Users.
- The bridge table handles multiple categories per commission.
- A unique constraint on `Reviews.commission_id` prevents duplicate reviews.
- Payments are a separate table so a deposit and a final payment can both be recorded.
- Artwork versions are numbered per commission and must be unique within it.
- CHECK constraints enforce valid ratings and positive prices.

## 5. Challenges
- **Modeling categories.** A commission can have many categories and a category applies to many commissions so I needed a bridge table with a composite primary key.
- **Referential integrity.** Deciding what happens when a parent row is deleted led me to use `ON DELETE CASCADE` on child tables.
- **Where to put status and versions.** Status lives on Commissions while versions live on Artworks with a uniqueness rule.
- **Derived data.** Average rating could go stale so I used a trigger. It only handles inserts which I noted as a limitation.
- **Sample data consistency.** My first draft had a review on a commission that was still in progress. I fixed it so the reviewed commission is completed.

## 6. Testing
Running the full SQL script in MySQL gave no errors. From there I confirmed all 12 tables were created, the sample queries returned the rows I expected and the trigger updated the artist's rating_avg once the sample review was inserted.

## 7. Outcomes
The result is a working MySQL database with a matching Chen diagram, an EER diagram, .mwb model, and SQL script, along with documentation, all organized in a GitHub repository. Possible future work includes triggers for review updates and deletes, a check that the reviewer is the commission's client, and an application front end.

## 8. Files Delivered
See `README.md` for the repository structure.
