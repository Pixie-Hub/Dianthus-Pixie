class_name CollisionLayers

const INTERACTABLE: int = 1
const TERRAIN: int = 2
const PLAYER: int = 4
const ENEMY: int = 8
const PROJECTILE: int = 16
const BARRICADE: int = 32

const MASK_PLAYER: int = TERRAIN
const MASK_ENEMY: int = TERRAIN | BARRICADE
const MASK_PROJECTILE_PLAYER: int = TERRAIN | ENEMY
const MASK_INTERACTABLE: int = PLAYER
