port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Animation exposing (px)
import Animation.Spring.Presets
import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D


sideLength =
    100


halfSideLength =
    50


type alias Pos =
    { x : Int, y : Int }


type alias Player =
    { pos : Pos, colour : String, name : String, style : Animation.State }


main : Program () Model Msg
main =
    Browser.element
        { init = always init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { me : Player, others : List Player }


init : ( Model, Cmd Msg )
init =
    ( { me =
            { pos = { x = 0, y = 0 }
            , colour = "silver"
            , name = "Mario"
            , style =
                Animation.style
                    [ Animation.left (px 0), Animation.top (px 0) ]
            }
      , others = []
      }
    , Cmd.none
    )


type Direction
    = Left
    | Right
    | Up
    | Down
    | Other


keyDecoder : D.Decoder Direction
keyDecoder =
    D.map toDirection (D.field "key" D.string)


toDirection : String -> Direction
toDirection string =
    case string of
        "ArrowLeft" ->
            Left

        "ArrowRight" ->
            Right

        "ArrowUp" ->
            Up

        "ArrowDown" ->
            Down

        _ ->
            Other


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Animation.subscription Animate [ model.me.style ]
        , Browser.Events.onKeyDown (D.map Move keyDecoder)
        ]


type Msg
    = Animate Animation.Msg
    | Move Direction


updatePlayer : Player -> Int -> Int -> Player
updatePlayer player x y =
    let
        newPos =
            { x = x, y = y }

        xpx =
            toFloat (x * sideLength)

        ypx =
            toFloat (y * sideLength)
    in
    { player
        | pos = newPos
        , style =
            Animation.interrupt
                [ Animation.toWith
                    (Animation.spring Animation.Spring.Presets.wobbly)
                    [ Animation.left (px xpx)
                    , Animation.top (px ypx)
                    ]
                ]
                player.style
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update action ({ me } as model) =
    case action of
        Move direction ->
            let
                ( dx, dy ) =
                    case direction of
                        Left ->
                            ( -1, -1 )

                        Right ->
                            ( 1, 1 )

                        Up ->
                            ( 1, -1 )

                        Down ->
                            ( -1, 1 )

                        Other ->
                            ( 0, 0 )
            in
            ( { model | me = updatePlayer model.me (me.pos.x + dx) (me.pos.y + dy) }
            , wsSend "something"
            )

        Animate animMsg ->
            ( { model
                | me = { me | style = Animation.update animMsg me.style }
              }
            , Cmd.none
            )


view : Model -> Html Msg
view ({ me } as model) =
    div
        []
        [ square me.style
        ]


square stylefn =
    div
        ([ style "position" "absolute"
         , style "left" "0px"
         , style "padding" "0px"
         , style "width" (String.fromFloat halfSideLength ++ "px")
         , style "height" (String.fromFloat halfSideLength ++ "px")
         , style "background-color" "#268bd2"
         , style "color" "white"
         ]
            ++ Animation.render stylefn
        )
        []


port wsSend : String -> Cmd msg
