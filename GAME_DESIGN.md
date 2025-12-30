# Pointfire - Game Design Document

## Vision
A 5v5 tactical arena shooter emphasizing weighted movement, fast TTK, and skillful play. Dark, grimy, low-poly aesthetic focused on immersive sound design and tactical gameplay.

## Core Pillars
- **Tactical Depth**: Weighted movement, positioning, and decision-making matter
- **Skill Expression**: Fast TTK rewards accuracy and game sense
- **Meaningful Progression**: Grind for cosmetics, weapons, attachments, and gear
- **Atmospheric Immersion**: Dark, raw aesthetic with sound-focused environment

---

## Game Modes

### MVP: Team Deathmatch (5v5)
- **Win Condition**: First team to win 5 rounds
- **Round Format**: No respawns - elimination only
- **Round Timer**: TBD (likely 2-3 minutes)
- **Economy/Loadout**: TBD (start with preset loadouts, add economy later)

### Future Modes
- **Bomb Plant/Defuse** (CS-style)
- **Hostage Rescue**
- **Heist Scenarios**
- Other objective-based modes

---

## Player Mechanics

### Movement System
- **Base Movement**: Weighted, tactical feel similar to Tarkov
  - Acceleration/deceleration (no instant movement)
  - Momentum-based (not arcade stop-on-a-dime)
  - Movement penalties while shooting/ADSing
- **Weapon-Based Variation**:
  - Lightweight guns allow slightly more agile movement
  - Heavy guns/gear slow player down further
- **Movement Actions**:
  - Walk (quiet, slower)
  - Sprint (louder, weapon down)
  - Crouch (accuracy bonus, quieter, slower)
  - Jump (limited, stamina-based?)
  - Lean (future feature?)

### Combat System
- **Time to Kill (TTK)**: Fast and tactical like Tarkov
  - Headshots = instant/near-instant kill
  - Body shots = 2-4 shots depending on armor/weapon
  - Limb shots = reduced damage
- **Recoil**: Realistic patterns that require control/learning
- **Armor System**:
  - Protects against body shots
  - Degrades with damage
  - Different tiers (future feature)
- **Accuracy**:
  - Affected by movement, stance (crouch/stand), ADS vs hipfire
  - First shot accuracy important

### Health System
- **No regeneration** (hardcore tactical)
- Health values TBD (100 HP standard?)
- Armor absorbs damage separately

---

## Weapon Systems

### Weapon Categories
1. **Assault Rifles** (medium weight, balanced)
2. **SMGs** (lightweight, high mobility)
3. **Sniper Rifles** (heavy, slow, high damage)
4. **Shotguns** (close range, heavy)
5. **Pistols** (sidearm, lightweight)

### Attachment System
- **Optics**: Red dots, holos, scopes (1x-4x)
- **Grips**: Foregrips (recoil reduction)
- **Barrels**: Suppressors (sound), compensators (recoil)
- **Stocks**: Stability improvements
- **Magazines**: Extended mags (capacity)

### Weapon Progression
- Some weapons **level-locked** (grind to unlock)
- Attachments unlocked through weapon-specific progression
- Use `.tres` Resource files for weapon stats (damage, fire_rate, recoil_pattern, etc.)

---

## Equipment & Gear

### Tactical Equipment
- **Frag Grenades**: Lethal explosives
- **Flashbangs**: Blind/deafen enemies
- **Smoke Grenades**: Visual cover
- **Molotov/Incendiary**: Area denial (future)

### Armor/Gear
- **Body Armor**: Different tiers (basic, tactical, heavy)
- **Helmet**: Headshot protection
- **Backpack/Rig**: Carry capacity (future)

---

## Progression System

### Experience & Leveling
- **Player Level**: Overall account level
- **Weapon Mastery**: Individual weapon progression
- **Match XP**: Based on kills, objectives, round wins, team performance

### Unlockables

#### Cosmetic Rewards (Primary Focus)
- **Rare Skins**: Weapon skins with different rarities
- **Medals/Pins**: Displayed on player card/profile
- **Character Skins**: Operator outfits, helmets, gear
- **Weapon Charms**: Dangles on weapons
- **Victory Poses/Emotes** (future)

#### Gameplay Unlocks
- **Weapons**: Level-locked guns unlock as you progress
- **Attachments**: Unlock through weapon usage
- **Equipment**: Tactical gear unlocks

### Reward Tiers
- **Common**: Easy to obtain
- **Rare**: Moderate grind
- **Epic**: Significant achievement
- **Legendary**: Extremely rare, prestige items

---

## Audio Design (Future Priority)

### Environmental Audio
- Dark, grimy atmosphere through sound
- Footstep variations (surface types, movement speed)
- Ambient industrial/urban sounds
- Dynamic audio occlusion

### Weapon Audio
- Distinct weapon sounds for identification
- Suppressed vs unsuppressed
- Distant gunfire falloff
- Shell casings, reloads

---

## Visual Style

### Art Direction
- **Low-Poly Tactical**: Clean geometry, readable silhouettes
- **Dark & Grimy**: Muted colors, industrial environments
- **Raw & Gritty**: Weathered materials, dirty textures
- **High Contrast**: Clear enemy visibility despite dark aesthetic

### Lighting
- Dramatic lighting for atmosphere
- Shadows used tactically (hiding spots)
- Minimal bloom/post-processing for clarity

---

## Technical Considerations

### Performance Targets
- 60+ FPS target on mid-range hardware
- Low-poly art style helps performance
- Efficient networking for future multiplayer

### Future Multiplayer
- Design with networking in mind even for single-player prototype
- Server-authoritative architecture
- Lag compensation / client prediction

---

## MVP Scope (Phase 1)

### Must Have
- Single-player vs bots
- 1 map (simple 3-lane or arena layout)
- Basic movement system (weighted, crouch, sprint)
- 3-5 starter weapons (1 AR, 1 SMG, 1 sniper, 1 pistol)
- Basic shooting mechanics (recoil, ADS, hipfire)
- Health/armor system
- Round-based team deathmatch (5 rounds to win)
- Simple bot AI (can navigate, shoot, take cover)
- Basic UI (health, ammo, round counter, scoreboard)
- Placeholder art (low-poly greybox)

### Nice to Have
- 1-2 attachments per gun
- 1-2 equipment items (frag, flashbang)
- Basic progression (level tracking)
- Simple skin system
- Main menu / loadout screen

### Future Iterations
- Multiplayer networking
- More maps
- Full weapon roster
- Complete attachment system
- Advanced movement (inertia, vaulting, leaning)
- Full progression system
- Economy system (buy phase)
- Additional game modes
- Sound design pass
- Final art pass
