module View exposing (view)

import WebGL as GL
import Model exposing (Model)
import View.Common as Common
import View.Object as Object
import Model.Object exposing (invertScreen, isScreen)
import View.Lives as Lives
import Html exposing (Html)
import Html.Attributes exposing (width, height, style)
import Actions exposing (Action)


view : Model -> Html Action
view model =
  GL.toHtmlWith
    [ GL.Enable GL.DepthTest
    ]
    [ width model.size
    , height model.size
    , style [("display", "block")]
    ]
    ( case model.texture of
        Nothing ->
          []
        Just texture ->
          render texture model
    )


toMinimap : (Float, Float) -> (Float, Float)
toMinimap (x, y) =
  ( floor (x / 64) |> toFloat
  , floor (y / 64) |> toFloat
  )


render : GL.Texture -> Model -> List GL.Renderable
render texture model =
  let
    (x, y) = Model.mogee model |> .position

    offset = (x - 32 + 4, y - 32 + 5)

    (cx, cy) = toMinimap (x, y)

    allScr = model.objects
      |> List.filter isScreen
      |> List.map (.position >> toMinimap)

    maxX = List.maximum (List.map fst allScr) |> Maybe.withDefault 0
    minY = List.minimum (List.map snd allScr) |> Maybe.withDefault 0

    dot (x1, y1) =
      Common.rectangle
        (1, 1)
        (63 - maxX - 1 + x1, y1 - minY + 1, 0)
        ( if x1 == cx && y1 == cy then
            (255, 255, 0)
          else
            (100, 100, 100)
        )

    bg = Common.rectangle (64, 64) (0, 0, 6) (22, 17, 22)

    monster {position, size} =
      Common.rectangle size (fst position - fst offset, snd position - snd offset, 2) (22, 17, 22)

    offsetObject ({position} as object) =
      { object
      | position = (fst position - fst offset, snd position - snd offset)
      }

  in
    if model.state == Model.Stopped then
      (if model.score > 0 then (Lives.renderScore texture (32, 1, 0) model.score) else []) ++
      [ Lives.renderTitle texture (3, 14)
      , Lives.renderPlay texture (5, 44, 0)
      , bg
      ]
    else
      (if model.state == Model.Paused then [Lives.renderPlay texture (5, 44, 0)] else []) ++
      Lives.renderLives texture (1, 1, 0) model.lives ++
      Lives.renderScore texture (32, 1, 0) (model.currentScore + model.score) ++
      List.map dot allScr ++
      List.foldl (Object.render texture) [bg] (List.map offsetObject model.objects)
