# LilithHelper

LilithHelper is a Windower 4 addon for Final Fantasy XI designed to automate the repetitive setup and travel involved in farming the **Maiden's Phantom Gem HTMB**.

The addon handles key item acquisition, Home Point travel, party synchronization, movement to the Veridical Conflux, and HTMB entry so that the player can focus on manually completing the fight itself.

LilithHelper supports both **solo play** and **multi-character parties**, including IPC commands for controlling multiple Windower instances at once.

## Features

- Automatically acquires the **Maiden's Phantom Gem** from Trisvain.
- Checks available merit points directly through Trisvain's HTMB menu.
- Automatically travels between **Northern San d'Oria** and **Selbina**.
- Automatically moves characters between Home Points, the KI NPC, and the Veridical Conflux.
- Supports solo players and parties.
- Automatically detects the party leader.
- Party members wait in Selbina while the leader handles HTMB entry.
- Party leader waits for all party members to arrive before queueing.
- Supports configurable HTMB difficulty.
- Detects entry into the Lilith battlefield.
- Remains active while the player manually completes the fight.
- Resumes automation after returning from the battlefield.
- Supports multi-client control through Windower IPC.
- Staggers multi-client startup to reduce simultaneous actions across multiple characters.
- Includes status and debug commands.

## Requirements

LilithHelper requires:

- superwarp addon
- Access to the Maiden's Phantom Gem HTMB
- Relevant Home Points unlocked

The addon currently expects the following Home Points to be available:

- Northern San d'Oria — Home Point #2
- Selbina — Home Point #1

## Installation

Place the addon in your Windower addons directory:

```text
Windower4/
└── addons/
    └── LilithHelper/
```

Load the addon with:

```text
//lua load lilithhelper
```

The addon supports both:

```text
//lilithhelper
```

and the shorter:

```text
//lh
```

command aliases.

## Commands

### Start

```text
//lh start
```

Starts LilithHelper on the current character.

### Stop

```text
//lh stop
```

Stops LilithHelper on the current character.

### Status

```text
//lh status
```

Displays the current LilithHelper status and automation phase.

### Debug

```text
//lh debug
```

Toggles debug logging.

### Difficulty

```text
//lh difficulty <VE|E|N|D|VD>
```

Sets the HTMB difficulty.

Available values:

```text
VE = Very Easy
E  = Easy
N  = Normal
D  = Difficult
VD = Very Difficult
```

For example:

```text
//lh difficulty VE
```

The selected difficulty is saved in the addon's settings and persists between sessions.

## Multi-Character IPC Commands

LilithHelper can discover and control other Windower instances running the addon.

### Start All

```text
//lh @all start
```

Discovers all active LilithHelper clients and starts the bot on each character.

Starts are staggered to prevent every character from issuing actions at exactly the same time.

### Stop All

```text
//lh @all stop
```

Stops LilithHelper on all connected clients.

### Status All

```text
//lh @all status
```

Requests status information from all connected LilithHelper clients.

Only `start`, `stop`, and `status` support the `@all` modifier.

## Automation Flow

LilithHelper is designed around a repeating farming cycle.

### 1. Check for Maiden's Phantom Gem

When started, LilithHelper checks whether the character already possesses the Maiden's Phantom Gem.

If the character already has the KI, acquisition is skipped.

If the character does not have the KI, LilithHelper proceeds to acquire one.

### 2. Travel to Northern San d'Oria

Characters that need a Maiden's Phantom Gem are routed to Northern San d'Oria.

The addon uses Home Point #2 as the starting location for the KI acquisition route.

### 3. Acquire the Key Item

LilithHelper moves the character to **Trisvain**.

The addon interacts with Trisvain and reads the HTMB menu information returned by the server.

This allows LilithHelper to determine:

- the character's current merit points;
- whether the Maiden's Phantom Gem is currently available for purchase.

The Maiden's Phantom Gem costs **10 merit points**.

If enough merits are available, LilithHelper purchases the KI and waits until possession of the Maiden's Phantom Gem is confirmed.

If fewer than 10 merit points remain, the farming cycle can no longer continue.

### 4. Return to Home Point #2

After acquiring the Maiden's Phantom Gem, the character returns to Northern San d'Oria Home Point #2.

LilithHelper then uses the Home Point to travel to Selbina.

### 5. Arrive in Selbina

Once in Selbina, behavior depends on the character's party status.

**Solo player**

The character proceeds toward the Veridical Conflux and prepares to enter the HTMB.

**Party leader**

The leader proceeds to the Veridical Conflux and waits for the rest of the party.

**Party member**

Regular party members remain in Selbina and wait for the party leader to initiate the battlefield.

They do not independently interact with the Veridical Conflux.

### 6. Party Synchronization

Before queueing the battlefield, the party leader verifies that all party members are present in Selbina.

The check repeats periodically until the entire party is detected.

Once everyone is present, LilithHelper waits briefly to allow the newly arrived characters to finish loading before interacting with the Veridical Conflux.

This helps prevent the battlefield queue from being created before the entire party is recognized.

### 7. Enter the Lilith HTMB

The solo player or party leader interacts with the **Veridical Conflux** and queues the battlefield using the configured difficulty.

LilithHelper supports:

```text
Very Easy
Easy
Normal
Difficult
Very Difficult
```

When the party enters the Lilith battlefield, LilithHelper detects **zone 279** and places each participating client into the fight state.

### 8. Fight Lilith Manually

LilithHelper does **not** automate combat.

Once inside the battlefield, the addon remains running but idle while the player manually completes the fight.

Combat, targeting, abilities, trusts, equipment changes, and battle strategy remain entirely under player control.

### 9. Return to Selbina

After the fight, characters normally return to Selbina.

LilithHelper detects the transition from the battlefield back to Selbina and resumes automation.

Characters are routed from the Veridical Conflux area back toward Selbina Home Point #1.

### 10. Repeat

The character returns to Northern San d'Oria and begins another KI acquisition cycle.

The process repeats:

```text
Acquire Maiden's Phantom Gem
        ↓
Travel to Selbina
        ↓
Gather party
        ↓
Enter Lilith HTMB
        ↓
Fight manually
        ↓
Return to Selbina
        ↓
Return to Northern San d'Oria
        ↓
Acquire next Maiden's Phantom Gem
```

The loop continues while another Maiden's Phantom Gem can be purchased.

## Starting From Different Locations

LilithHelper is designed to recover from several common starting states.

For example, a character may start:

- in Northern San d'Oria without the KI;
- in Northern San d'Oria with the KI;
- in Selbina with the KI;
- near the Veridical Conflux in Selbina;
- at any Home Point (within 5 yalms), with or without KI;
- as a party member waiting for the leader.

The bot determines the character's current state and attempts to continue from the appropriate point in the farming cycle rather than requiring every character to begin from exactly the same location.

## Party Behavior

Only the following characters are permitted to initiate the HTMB:

- a solo player;
- the current party leader.

Normal party members never attempt to interact with the Veridical Conflux independently.

This allows:

```text
//lh @all start
```

to be broadcast across an entire multibox party without every client attempting to queue the battlefield.

## Settings

LilithHelper stores configurable settings using Windower's configuration system.

The primary user setting is:

```text
difficulty
```

Example:

```text
VE
```

It can be changed at runtime with:

```text
//lh difficulty <VE|E|N|D|VD>
```

Users normally do not need to edit the settings file manually.

## Debugging

Debug logging can be enabled or disabled with:

```text
//lh debug
```

The current bot state can be inspected with:

```text
//lh status
```

For multi-character setups:

```text
//lh @all status
```

can be used to inspect all LilithHelper clients.

The phase reported by the status command can be useful for determining where a character is currently waiting in the automation process.

## Current Scope

LilithHelper automates the repetitive preparation surrounding the Maiden's Phantom Gem HTMB.

It is intentionally **not a combat bot**.

The intended workflow is:

> Automate the repetitive travel, KI acquisition, party gathering, and battlefield entry; manually play the fight; then allow LilithHelper to resume the farming loop afterward.

## Disclaimer

LilithHelper is a third-party Windower addon and is not affiliated with or endorsed by Square Enix or the Windower project.

Use third-party tools and addons at your own risk.