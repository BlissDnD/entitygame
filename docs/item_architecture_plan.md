# Item Architecture Plan

This document defines the long-term item architecture for the project and records the first implementation steps toward it.

It is a living plan, like the interaction plan. We should keep updating it as item count, item complexity, and world-item behavior grow.

## Goal

Build an item architecture that can support:

- many item definitions without file chaos
- shared behavior instead of one custom script per item
- clean links between items and systems such as equipment, interaction, placement, and use
- explicit item phases such as inventory, equipped, dropped, and placed
- future NPC use, crafting, loot tables, and world persistence

The big rule is:

- items should be data-first
- systems should do the work
- custom item scripts should be the exception, not the default

## Current State

Right now the repo has a good foundation, but item ownership is still spread across a few directions:

- `systems/items/item_definition.gd`
  - broad item data, capabilities, specialization flags, and optional links
- `systems/items/item_drop_data.gd`
  - floor-drop runtime data and physics/merge behavior
- `systems/items/item_interaction_controller.gd`
  - item-drop updates and special backpack world-item handling
- `entity/items/backpack_world_item.tscn`
  - one special dropped/equippable world representation
- `entity/item_pickup/item_pickup.tscn`
  - generic pickup actor
- `resources/items/`, `resources/backpacks/`, and `resources/cursor/`
  - editable item-facing resources

That is workable now, but it will become harder to scale if we keep mixing content type, world phase, and system ownership together.

## Core Direction

Each item should usually have:

1. one item definition resource
2. optional links to shared systems and shared world-phase resources
3. no custom script unless the item is genuinely special

That means:

- `wood.tres` should stay data
- `basic_axe.tres` should stay data
- `scanner.tres` should stay data
- special one-off world actors can still exist, but they should be rare

## Recommended Folder Structure

The target direction is category-based item content folders under `resources/items/`, with one definition file per item.

```text
resources/items/
  materials/
    wood.tres
    stone.tres
  salvage/
    scrap.tres
  devices/
    scanner.tres
  placeable_items/
    test_placeable_box.tres
  equipment/
    tools/
      basic_mining_tool.tres
      basic_axe.tres
    backpacks/
      basic_backpack.tres
```

Notes:

- this layout is now the active direction for current and new item content
- one file per item definition is good
- category folders scale better than one giant flat item folder
- we should avoid creating one script file per normal item

## Item Phases

Every item should be thought of as moving through phases.

The important phases are:

1. definition phase
   - what the item is
2. inventory phase
   - held in backpack/inventory as data
3. equipped phase
   - linked to slot/cursor/passive effects
4. dropped phase
   - exists as floor loot in the world
5. placed phase
   - becomes a placed world object if it supports placement

This matters because the same item can appear in different systems without becoming a different thing.

Example:

- `basic_axe.tres`
  - definition phase: tool/passive equipment item
  - equipped phase: sits in the passive slot
  - dropped phase: should later be able to exist as floor loot

- `wood.tres`
  - definition phase: material item
  - inventory phase: stacks in backpack
  - dropped phase: can spill onto the floor if inventory is full

## Item Definition Responsibilities

`item_definition.gd` should be the main hub for item identity and system links.

Good responsibilities for the definition:

- id
- display text
- category
- stack size
- weight/value
- capability flags
- equipment specialization flags
- cursor behavior link
- placeable link
- backpack link
- dropped-world link

The definition should declare what an item is and which shared systems it participates in.

The definition should not become a giant item-behavior script.

## World Drop Direction

Dropped items should become a first-class shared phase, not one special case per item.

Target direction:

- normal dropped items use the shared dropped-item runtime path
- special world actors are only used when truly needed
- floor-drop behavior should work like mining drops: hover, merge, gravity, pickup

We already started moving in this direction:

- tree wood can now spill onto the floor if backpack space runs out
- item drops now support non-material item definitions, not only mined terrain materials

What is still transitional:

- `backpack_world_item.tscn` is still a special-case dropped/equip actor
- generic dropped-item representation is not yet fully unified
- `item_definition.world_scene` is still ambiguous and should be treated as legacy world-phase glue

## Special vs Shared World Representations

Use shared systems by default.

Use a custom scene/script only when an item truly needs unique world behavior.

Good shared/default cases:

- wood
- scrap
- stone
- scanner pickup
- normal loose equipment

Good special-case cases:

- backpack world item that equips directly on interaction
- large interactable placeables
- multi-step world devices
- actor-like equipment with unique world behavior

## Recommended Implementation Phases

### Phase 1: Architecture Clarification

Goal:

Make item definitions more explicit about world-phase links and document the long-term structure.

Deliverables:

- item architecture plan doc
- `item_definition.gd` cleanup for dropped-world references
- architecture doc updated to point at this plan

### Phase 2: Category Structure

Goal:

Move item definitions toward category folders without breaking the world.

Deliverables:

- create category subfolders under `resources/items/`
- migrate existing item definitions gradually
- update preload/resource paths carefully

### Phase 3: Shared Dropped Item Path

Goal:

Unify normal item floor drops under one shared representation.

Deliverables:

- generic dropped-item path for non-material items
- shared pickup behavior for dropped item definitions
- reduce one-off world item actor logic where possible

### Phase 4: Item Behavior Linking

Goal:

Let items link to reusable behavior resources/systems instead of growing ad hoc branches.

Examples:

- placeable link
- use behavior
- interaction requirements
- loot/spawn tables

### Phase 5: Content Scale Rules

Goal:

Make it safe to add lots of items.

Deliverables:

- category conventions
- naming rules
- item checklist for new content
- clear rule for when a new item gets only a `.tres` versus a custom scene/script

## Current Working Rules

Until the full migration is done, use these rules:

1. New normal items should usually be one `.tres` definition file.
2. Prefer category folders over adding more flat files.
3. Keep system logic shared when possible.
4. Treat dropped state as a standard item phase, not an exception.
5. Add a custom item script only when shared data and shared systems are not enough.

## Started Work

Work already started from this plan:

- item definitions now have a clearer dropped-world direction
- tree-yield item overflow already uses the shared floor-drop runtime path
- item pickup logic now supports non-material item drops feeding into the backpack system
- current item definitions have been moved into category folders under `resources/items/`
- current item definitions now explicitly declare world behavior, interaction conditions, default world state, and lifespan defaults

## Next Best Step

After this doc, the next safe implementation step is:

1. keep using shared item-drop runtime for normal dropped items
2. replace more legacy direct field usage with helper methods on `item_definition.gd`
3. introduce a more generic dropped-item representation for normal loose non-material items
