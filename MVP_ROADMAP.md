# Pointfire - MVP Development Roadmap

## Goal
Build a playable single-player 5v5 team deathmatch prototype with bots, demonstrating core tactical shooter mechanics and weighted movement.

---

## Phase 1: Foundation & Player Movement
**Goal**: Player moving with weighted, tactical movement feel.

### Tasks
- [ ] Set up project structure (folders for scenes, scripts, resources, assets)
- [ ] Create basic test map (greybox arena with simple geometry)
- [ ] Create Player scene (CharacterBody3D)
  - [ ] Basic collision shape (capsule)
  - [ ] Camera3D (first-person)
  - [ ] Placeholder mesh
- [ ] Implement MovementComponent
  - [ ] WASD movement with acceleration/deceleration
  - [ ] Sprint (Shift key)
  - [ ] Crouch (Ctrl key)
  - [ ] Jump (Space)
  - [ ] Mouse look (camera rotation)
  - [ ] Movement speed affected by weight variable
- [ ] Test and tune movement feel

**Deliverable**: Player can move around test map with weighted movement.

---

## Phase 2: Weapons & Shooting
**Goal**: Implement shooting mechanics with hitscan weapons.

### Tasks
- [ ] Create WeaponData resource class
- [ ] Create 2-3 weapon data files (.tres): AR, SMG, Sniper
- [ ] Implement WeaponComponent
  - [ ] Hitscan shooting (raycast from camera)
  - [ ] Fire rate limiting
  - [ ] Magazine system and reload
  - [ ] ADS (right click)
  - [ ] Recoil pattern application
  - [ ] Movement speed affected by weapon weight
- [ ] Add crosshair UI
- [ ] Add muzzle flash and bullet impact effects

**Deliverable**: Player can shoot weapons with different stats, reload, and ADS.

---

## Phase 3: Health & Damage
**Goal**: Implement damage system.

### Tasks
- [ ] Implement HealthComponent
- [ ] Implement ArmorComponent
- [ ] Connect shooting to damage (headshots, body, limbs)
- [ ] Create basic HUD (health, armor, ammo)
- [ ] Implement death state
- [ ] Add hit markers and damage indicators

**Deliverable**: Player can take damage, see health/armor, and die.

---

## Phase 4: Game Loop & Teams
**Goal**: Round-based team deathmatch structure.

### Tasks
- [ ] Create GameManager (Autoload)
- [ ] Create RoundManager (states, timer, win conditions)
- [ ] Create SpawnManager (team spawn points)
- [ ] Implement team system (Team A vs Team B)
- [ ] Create Scoreboard UI (Tab to toggle)
- [ ] Update HUD with round info

**Deliverable**: Full round-based game loop works.

---

## Phase 5: AI & Bots
**Goal**: Add bot players for 5v5 matches.

### Tasks
- [ ] Set up NavigationRegion3D and bake navmesh
- [ ] Create Bot scene (reuses player components)
- [ ] Implement BotBehavior state machine
  - [ ] PATROL: Move to random waypoints
  - [ ] SEARCH: Look for enemies
  - [ ] ENGAGE: Shoot at visible enemy
- [ ] Spawn 5 bots per team
- [ ] Tune bot difficulty

**Deliverable**: Working 5v5 bot matches with full round structure.

---

## Phase 6: Content & Equipment
**Goal**: Add weapon variety and basic equipment.

### Tasks
- [ ] Create 5+ weapons across categories
- [ ] Implement weapon switching (1, 2 keys)
- [ ] Add frag grenade and flashbang
- [ ] Create basic loadout system
- [ ] Balance pass

**Deliverable**: Multiple weapons and grenades working.

---

## Phase 7: Polish & Feel
**Goal**: Make the game feel satisfying.

### Tasks
- [ ] Audio (weapons, footsteps, hits, UI)
- [ ] Visual polish (muzzle flash, shells, blood, death effects)
- [ ] Camera effects (shake, recoil, head bob)
- [ ] UI polish (kill feed, announcements)
- [ ] Map improvements (cover, lighting, dark grimy aesthetic)
- [ ] Feel tuning pass

**Deliverable**: Game feels satisfying to play.

---

## Phase 8: Main Menu & Game Flow
**Goal**: Complete game flow from launch to gameplay.

### Tasks
- [ ] MainMenu scene (Play, Settings, Quit)
- [ ] LoadoutMenu scene
- [ ] Scene transitions
- [ ] Post-match screen

**Deliverable**: Complete game flow from launch to match completion.

---

## Testing Milestones

| Milestone | Phase | Criteria |
|-----------|-------|----------|
| "I can move and shoot" | 2 | Weighted movement, shooting works |
| "Combat works" | 3 | Damage, health, death functional |
| "Rounds work" | 4 | Full round structure, teams, scores |
| "It's a game" | 5 | 5v5 bot matches playable |
| "MVP Complete" | 7 | Polished, feels like a real game |

---

## Post-MVP Features

**Short-term**: More maps, attachments, economy system, advanced bot AI
**Medium-term**: Multiplayer networking, additional game modes (bomb, hostage, heist), progression expansion
**Long-term**: Advanced movement (inertia, vaulting, leaning), ranked matchmaking, seasonal content

---

## Success Criteria

MVP is complete when:
- Player moves with weighted, tactical feel
- Multiple weapons with distinct characteristics
- Health/armor damage system works
- Round-based 5v5 team deathmatch functions
- Bots navigate, shoot, and play tactically
- Audio/visual feedback makes combat satisfying
- Code structured for future multiplayer
