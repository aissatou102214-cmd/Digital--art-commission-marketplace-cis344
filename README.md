# Digital Art Commission Marketplace — CIS 344

Aissatou Barry
Lehman College
CIS 344, Fall 2026
Prof. Yanilda Peralta Ramos
September 29, 2026

## Project Overview
This project designs and implements a MySQL relational database for a Digital Art Commission Marketplace (an online system where clients request custom digital artwork from artists.) The database tracks accounts, artist and client profiles, portfolios, commission types, commission requests, categories, messages, artwork versions and payments as well as reviews.

## Repository Structure
```
digital-art-commission-marketplace-cis344/
├── README.md
├── sql/
│   └── digital_art_commission_marketplace.sql   # creates database, 12 tables, trigger, view, sample data, queries
├── workbench/
│   └── digital_art_commission_marketplace.mwb   # MySQL Workbench model (EER diagram)
├── diagrams/
│   ├── chen_er_diagram.jpg                      # hand-drawn Chen diagram (photo/scan)
│   └── uml_er_diagram.png                       # exported from MySQL Workbench
└── docs/
    ├── process_documentation.md                 # mini world, requirements, design decisions
    └── final_report.md                          # scope, structure, decisions, challenges, outcomes
```

## Database Summary
| Table | Purpose |
|---|---|
| Users | All accounts (client / artist / admin) |
| ArtistProfiles, ClientProfiles | Role-specific data (1 User : 0..1 profile) |
| Commissions | Central entity linking a client and an artist |
| Categories, CommissionCategories | Many-to-many categories per commission |
| Artworks | Versioned deliverables per commission |
| Payments | Deposits / final payments per commission |
| Messages | Conversation per commission |
| Reviews | At most one review per commission |
| PortfolioItems, CommissionTypes | Artist portfolio and services offered |


