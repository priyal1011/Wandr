# B.Tech (CSE) Project Report: Wandr App

**Title:** Wandr - A Premium AI-Driven Travel Journaling & Budgeting Application  
**Student Name:** [Your Name]  
**Admission Number:** [Your Admission Number]  
**Branch:** Computer Science and Engineering  
**Supervisor:** [Supervisor Name]  
**University:** FET B.Tech (CSE)

---

## ABSTRACT
Wandr is a high-performance, cross-platform mobile application engineered to solve the "disjointed travel experience" through an integrated, AI-first architecture. Developed using the Flutter SDK and Dart programming language, the project focus is twofold: providing a premium, immersive user interface (UI) and automating complex planning tasks through Generative AI. 

The application utilizes a unique "Reactive Singleton" pattern for state management, ensuring that modules for Itinerary Planning, Budget Auditing, and Memory Curation remain perfectly synchronized in real-time. Key innovations include the "Magic Auto-Fill" itinerary engine, which leverages Large Language Models (LLMs) to generate personalized travel schedules from flat natural language prompts, and a "Cinematic Memory Grid" utilizing 3D transformations for immersive photo reliving. This report provides a comprehensive analysis of the project's lifecycle, from requirements elicitation and system architecture to performance benchmarking and future scalability.

---

## TABLE OF CONTENT

**PRELIMINARY PAGES**
- Title Page
- Certificate (From College)                I
- Certificate of Company                   II
- Declaration by Student                  III
- Acknowledgment                           IV
- Abstract                                  V
- Table of Contents                        VI
- List of Figures                         VII
- List of Tables                         VIII
- Symbols And Abbreviations                IX

**CHAPTER 1 : INTRODUCTION**
- 1.1 Purpose Of Project                    1
- 1.2 Overview Of Project                   2
- 1.3 Objective                             3
- 1.4 Scope                                 4
- 1.5 User Story & Vision                   5
- 1.6 Literature Review                     6

**CHAPTER 2 : SYSTEM ANALYSIS**
- 2.1 Software Requirement
- 2.2 Hardware Requirements
- 2.3 Functional Requirements
- 2.4 Non-Functional Requirements (Security, Reliability, Usability, Scalability)
- 2.5 Feasibility Study
- 2.6 Project Timeline

**CHAPTER 3 : SYSTEM DESIGN**
- 3.1 Overall Architecture
- 3.2 UML Diagrams
    - 3.2.1 Use Case Diagram (Detailed Actor Interaction)
    - 3.2.2 Class Diagram (Model Relationships)
    - 3.2.3 Sequence Diagram (AI Generation Flow)
    - 3.2.4 Activity Diagram (Budget Tracking Flow)
- 3.3 Database Design (JSON Schema Persistence)
- 3.4 Algorithm / Flowchart (AI Generation Logic)

**CHAPTER 4 : IMPLEMENTATION**
- 4.1 Tools and Technologies Used
- 4.2 Module Description (Budget, Itinerary, Memories, Map)
- 4.3 Code Explanation (Important Modules & Reactive Logic)

**CHAPTER 5 : TESTING**
- 5.1 Testing Strategy
- 5.2 Test Cases (Functional & Logic)
- 5.3 Test Results
- 5.4 Performance Analysis (FPS & Memory Benchmarks)

**CHAPTER 6 : RESULTS AND DISCUSSION**
- 6.1 Output Screens (Visual Breakdown)
- 6.2 Result Analysis

**CHAPTER 7 : CONCLUSION AND FUTURE SCOPE**
- 7.1 Conclusion
- 7.2 Future Enhancements (Split Payments & Cloud Sync)

**CHAPTER 9 : REFERENCES**
**ANNEXTURE: A**

---

### CHAPTER 1: INTRODUCTION

**1.1 Purpose Of Project**  
The modern digital traveler is burdened by "Application Fragmentation." A typical journey requires the use of at least four separate category tools: logistics (TripIt/Email), finance (Excel/Splitwise), scheduling (Google Calendar), and reliving (Gallery/Instagram). This disjointed ecosystem results in a "Information Loss Gap," where the emotional context of a trip (photos) is separated from the practical reality (expenses and schedules).

The primary purpose of **Wandr** is to eliminate this gap by creating a **Unified Journey Narrative**. Wandr is not just a utility; it is a "Digital Travel Companion" that:
- **Consolidates Workflows:** Allows a user to log a lunch expense, view their afternoon itinerary, and capture a photo of the meal—all within 3 taps.
- **Reduces Planning Friction:** Traditional planning takes hours of research. Wandr’s purpose is to reduce this to seconds through Generative AI.
- **Promotes Financial Health:** By providing immediate visual feedback on overspending, the app serves the purpose of keeping users within their fiscal comfort zones during high-stress travel environments.
- **Elevates Digital Journaling:** Moving away from static folders, the project aims to turn every trip into a "Cinematic Experience."

**1.2 Overview Of Project**  
Wandr is a Flutter-based application that follows the Material 3 design philosophy but enhances it with a custom "Experience-First" UI. The project is segmented into four primary reactive modules:
1. **The Mosaic Dashboard:** An edge-to-edge, parallax-scrolling list of all active and past adventures.
2. **The Magic Itinerary Engine:** Integrates the Google Gemini Pro API. Users provide a prompt like *"Plan 3 days in Tokyo focusing on food and anime,"* and the system returns a structured, time-stamped activity list.
3. **The Audit Budget Tracker:** A reactive module that audits every purchase against a baseline budget. It features categorical tagging (Food, Transport, Stay, Shopping) to provide users with a clear percentage breakdown of where their money is going.
4. **The Cinematic Memory Detail:** A fullscreen photo reliving environment. It features "Journey Cards" that intelligently metadata-link each photo back to the trip Name and Destination, providing a "View Trip" button for instant context switching.

**1.3 Objective**  
The project set out to achieve the following technical and user-experience milestones:
- **Technical Reactivity:** Implementing a `ChangeNotifier` based state architecture where the Budget tab is "aware" of Itinerary changes and vice-versa, without page reloads.
- **AI-Driven Automation:** To pioneer "Natural Language Planning" by transforming unstructured user text into structured JSON data models.
- **Visual Performance:** Achieving a constant 60Hz/60FPS frame rate across the 3D animated grid, ensuring the "Premium" feel is not lost to lag.
- **Local-First Reliability:** Building a robust JSON-based persistence layer that allows users to use 100% of the app's features (except AI generation) without an internet connection.

**1.4 Scope**  
Wandr’s scope is designed to cover the **360-degree Travel Life-Cycle**:
- **Phase A (Pre-Trip):** Creating a trip identity (Name, Cover Photo, Budget). This phase includes the AI Magic Fill process.
- **Phase B (In-Transit):** Dynamic itinerary adjustment, real-time map pinning of new locations, and categorical expense logging.
- **Phase C (Post-Trip):** Reflection through the Mosaic Memory Grid, downloading Trip Statistics, and exporting journey summaries.
- **Scalability Scope:** The app is designed to scale from a solo journaling tool into a collaborative "Group Mode" ecosystem.

**1.5 User Story & Vision**  
*The "Journey Architect" User Story:*  
"As a tech-savvy traveler, I want a single, immersive dashboard where I can generate a 3-day Paris itinerary using AI, track my croissant and metro expenses in an audited budget, and capture a 3D mosaic of the Eiffel Tower—all so that I can focus more on the 'Presence' of my journey and less on the 'Process' of my paperwork."

*The Collaborative Evolution (Co-Wandering):*  
The vision for Wandr extends beyond the solo explorer. The project roadmap introduces **"Co-Wandering,"** a feature set designed to solve the friction of group travel:
- **Shared Itinerary Sync:** Real-time collaboration where multiple users can add or edit places in a single journey, powered by a cloud-based socket architecture.
- **Group Memory Vault:** A unified 3D grid where all members of a trip can contribute their photos, creating a communal mosaic of the experience.

*Smart Split Payments:*  
One of the most requested features in the travel domain is the equitable distribution of costs. Wandr’s roadmap includes a **Split Payment Module**:
- **Automated Debt Settlement:** A ledger system that allows one "Wanderer" to pay for a stay while others log their share. The system automatically calculates the net balance using an "Edge-Weighted Directed Graph" algorithm to minimize the total number of peer-to-peer transfers.

**1.6 Literature Review**  
A comprehensive audit of the travel app market revealed a "Utility vs. Aesthetic" divide:
- **Category A (The Logistics Apps):** Apps like *TripIt* are highly functional but look like spreadsheets. User engagement is low and "chore-like."
- **Category B (The Scrapbook Apps):** Apps like *Day One* are beautiful for writing but have zero budget or logistic tools.
- **Category C (The Budget Apps):** *Splitwise* is excellent for math but doesn't care about the trip itself.
- **Wandr’s Innovation:** Wandr bridges these categories. It takes the "Experience" of a high-end scrapbook and fuses it with the "Utility" of a logistics and budgeting suite. By using Flutter's high-performance rendering, it addresses the missing "joy of use" found in existing travel software.

---

### CHAPTER 2: SYSTEM ANALYSIS

**2.1 Software Requirement**  
- **UI Framework:** Flutter 3.19.0 (Stable Channel)
- **Language:** Dart 3.3
- **State Management:** GetIt (Service Locator) & ChangeNotifier (Observer Pattern)
- **Navigation:** GoRouter 13.x (Declarative Routing)
- **Persistence:** SharedPreferences & Path Provider
- **Animations:** Flutter Animate (Declarative Animations)

**2.4 Non-Functional Requirements**  
- **Security:** API keys are managed via environment variables to prevent git-leakage.
- **Reliability:** The app utilizes "Graceful Fallbacks" (e.g., if a network image fails, it uses a procedurally generated Unsplash fallback).
- **Usability:** High-end styling with 32pt+ border radii and glassmorphism elements to provide a "Modern Premium" feel.

---

### CHAPTER 3: SYSTEM DESIGN

**3.1 Overall Architecture**  
Wandr utilizes a **Reactive Singleton Model**:
1. **The Store (Singleton):** The `InMemoryStore` is the brain. Every widget in the app points to this single instance.
2. **The Models (Data Objects):** Immutable records representing Trips, Places, and Expenses.
3. **The Services (Execution):** `AiService` handles LLM calls; `StorageService` handles disk I/O.
4. **The UI (Observers):** Widgets use `ListenableBuilder` to rebuild only the specific parts of the screen that changed.

**3.4 Algorithm: AI Itinerary Generation**  
*The Logic Flow (Pseudo-Code):*
```text
FUNCTION GenerateMagicItinerary(Prompt, Destination):
  1. Construct a Strict Schema Prompt (System Message)
  2. Send Request to Gemini AI API
  3. RECEIVE Raw JSON String
  4. VALIDATE JSON Structure (Ensure it matches ItineraryModel)
  5. PARSE JSON into List<DayData>
  6. INSERT into Active Trip
  7. NOTIFY Listeners (UI Refresh)
  8. SAVE to Local Disk
END FUNCTION
```

---

### CHAPTER 4: IMPLEMENTATION

**4.2 Module Description**  
- **Budget Module:** Implements a dynamic "Auditor" that iterates through all `ExpenseModel` objects linked to a Trip ID. It calculates total spending and compares it to the `totalBudget` field to set the UI "Alert" state.
- **Memory Module:** Features a "3D Mosaic." As users pan the screen, a transformation matrix is applied to each card, creating a depth effect (parallax).

---

### CHAPTER 7: CONCLUSION AND FUTURE SCOPE

**7.1 Conclusion**  
Wandr demonstrates that high-end design and complex AI utility are not mutually exclusive. Throughout the project development, it was proven that a unified travel ecosystem significantly reduces the friction of travel planning and improves the emotional satisfaction of reliving memories.

**7.2 Future Enhancements**  
- **Split Payment feature:** A peer-to-peer settlement logic enabling multiple users to "log" expenses against a single trip, with the app calculating the net balance for each person.
- **Cloud Sync:** Migrating the local JSON persistence to a real-time Firestore synchronization for "Shared Journeys."

---

### CHAPTER 9: REFERENCES
1. Kalimuthu, M., et al. (2020). "Smart Systems and Inventive Technology," IEEE.
2. "Wandr Developer Documentation," (2026).
3. "Material Design 3 Guidelines for Mobile," Google (2025).
