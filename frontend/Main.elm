port module Main exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Animation exposing (px)
import Animation.Spring.Presets
import Browser
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Json.Encode as E


sideLength =
    100


halfSideLength =
    50


type alias Pos =
    { x : Int, y : Int }


type alias BasicPlayer =
    { x : Int, y : Int, colour : String, name : String }


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
            , style = Animation.style [ Animation.left (px 0), Animation.top (px 0) ]
            }
      , others = []
      }
    , Cmd.none
    )


mergePlayers : List BasicPlayer -> List Player -> List Player
mergePlayers newList oldList =
    let
        oldOne p =
            oldList
                |> List.filter (\o -> o.name == p.name)
                |> List.head

        mapNew n =
            case oldOne n of
                Nothing ->
                    Debug.log "newplayer!" <|
                        buildPlayer n

                Just o ->
                    Debug.log "updatedplayer!" <|
                        updatePlayer o n.x n.y
    in
    newList
        |> List.map mapNew


buildPlayer ({ x, y, colour, name } as basicPlayer) =
    { pos = { x = x, y = y }
    , colour = colour
    , name = name
    , style =
        Animation.style
            [ Animation.left (px (toFloat (x * sideLength)))
            , Animation.top (px (toFloat (y * sideLength)))
            ]
    }


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
        [ Animation.subscription Animate ([ model.me.style ] ++ List.map .style model.others)
        , Browser.Events.onKeyDown (D.map Move keyDecoder)
        , activeUsers UserUpdate
        ]


type Msg
    = Animate Animation.Msg
    | Move Direction
    | UserUpdate (List BasicPlayer)


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
        UserUpdate players ->
            let
                oldy =
                    Debug.log "old-pos" (List.map .pos model.others)

                count =
                    Debug.log "new-pos" (List.map .pos others)

                others =
                    mergePlayers players model.others
                        |> Debug.log "mergedplayers"
            in
            ( { model | others = others }, Cmd.none )

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

                ( newx, newy ) =
                    ( me.pos.x + dx, me.pos.y + dy )
            in
            ( { model | me = updatePlayer model.me newx newy }
            , wsSend ( newx, newy )
            )

        Animate animMsg ->
            ( { model
                | me = { me | style = Animation.update animMsg me.style }
                , others = List.map (\o -> { o | style = Animation.update animMsg o.style }) model.others
              }
            , Cmd.none
            )


view : Model -> Html Msg
view ({ me } as model) =
    div
        []
        ([]
            ++ (model.others |> List.filter (\o -> o.name /= me.name) |> List.map square)
            ++ [ square me ]
        )


square player =
    div
        ([ style "position" "absolute"
         , style "left" "0px"
         , style "padding" "0px"
         , style "width" (String.fromFloat halfSideLength ++ "px")
         , style "height" (String.fromFloat halfSideLength ++ "px")
         , style "background-color" player.colour
         ]
            ++ Animation.render player.style
        )
        []


port wsSend : ( Int, Int ) -> Cmd msg


port activeUsers : (List BasicPlayer -> msg) -> Sub msg
