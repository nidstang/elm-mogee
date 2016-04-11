module Object (Object, Category(..), update, wall, mogee, collide) where

import Math.Vector2 as Vec2 exposing (Vec2, vec2)
import Mogee exposing (Mogee)
import Time exposing (Time)


type Category
  = WallCategory
  | MogeeCategory Mogee


type alias Keys =
  { x : Int
  , y : Int
  }


type Physics
  = Static
  | Gravity Float


type alias Object =
  { category : Category
  , physics : Physics
  , size : Vec2 -- dimensions
  , position : Vec2 -- the top left corner
  }


gravity : Float
gravity = 0.0001


jumpVelocity : Float
jumpVelocity = -0.05


walkVelocity : Float
walkVelocity = 0.03


mogee : Vec2 -> Object
mogee =
  Object (MogeeCategory Mogee.mogee) (Gravity 0) (vec2 7 10)


wall : Vec2 -> Vec2 -> Object
wall =
  Object WallCategory Static


moveY : Time -> Float -> Float -> List Object -> Object -> Object
moveY dt dy velocity objects object =
  let
    newVelocity = velocity + gravity * dt
    deltaY = dt * velocity + 0.5 * gravity * dt * dt
    newObject =
      { object
      | position = vec2 0 deltaY |> Vec2.add object.position
      , physics = Gravity newVelocity
      }
    collisions = List.filter (collide newObject) objects
    x = Vec2.getX object.position
  in
    case List.head collisions of
      Nothing -> newObject
      Just {position, size} ->
        if deltaY < 0 then
          {- Jumping up -}
          { object
          | physics = Gravity -velocity
          , position = vec2 x (Vec2.getY position + Vec2.getY size)
          }
        else
          {- Falling down -}
          { object
          | physics = if dy == 1 then Gravity jumpVelocity else Gravity 0
          , position = vec2 x (Vec2.getY position - Vec2.getY object.size)
          }


moveX : Time -> Float -> List Object -> Object -> Object
moveX dt dx objects object =
  let
    deltaX = dt * dx * walkVelocity
    newObject =
      { object
      | position = Vec2.add object.position (vec2 deltaX 0)
      }
    collisions = List.filter (collide newObject) objects
    y = Vec2.getY object.position
  in
    case List.head collisions of
      Nothing -> newObject
      Just {position, size} ->
        if deltaX < 0 then
          {- Hit the left wall -}
          { object
          | position = vec2 (Vec2.getX position + Vec2.getX size) y
          }
        else
          {- Hit the right wall -}
          { object
          | position = vec2 (Vec2.getX position - Vec2.getX object.size) y
          }


update : (Time, Keys) -> List Object -> Object -> Object
update (dt, keys) objects object =
  case object.physics of
    Static ->
      object
    Gravity velocity ->
      let
        restObjects = List.filter ((/=) object) objects
      in
        object
        |> moveY dt (toFloat keys.y) velocity restObjects
        |> moveX dt (toFloat keys.x) restObjects


collide : Object -> Object -> Bool
collide o1 o2 =
  let
    (x1, y1) = Vec2.toTuple o1.position
    (w1, h1) = Vec2.toTuple o1.size
    (x2, y2) = Vec2.toTuple o2.position
    (w2, h2) = Vec2.toTuple o2.size
  in
    x1 < x2 + w2 && x1 + w1 > x2 &&
    y1 < y2 + h2 && y1 + h1 > y2