module Tests exposing (..)

import Expect exposing (..)
import NavegableList exposing (..)
import String
import Test exposing (..)


all : Test
all =
    describe "application"
        [ navegableList
        ]


navegableList : Test
navegableList =
    describe "Navegable list"
        [ describe "empty list"
            [ test "focus is undefined" <|
                \_ ->
                    Expect.equal Nothing (focusedElement empty)
            , test "focusNext has no effects" <|
                \_ ->
                    Expect.equal Nothing (empty |> focusNext |> focusedElement)
            , test "focusPrevious has no effects" <|
                \_ ->
                    Expect.equal Nothing (empty |> focusPrevious |> focusedElement)
            ]
        , describe "creation"
            [ describe "empty"
                [ test "elements" <|
                    \_ ->
                        Expect.equal [] (toList empty)
                , test "focus" <|
                    \_ ->
                        Expect.equal Nothing (focusedElement empty)
                ]
            , describe "fromList"
                [ test "elements" <|
                    \_ ->
                        Expect.equal [ 1, 2, 3 ] ([ 1, 2, 3 ] |> fromList |> toList)
                , test "focus" <|
                    \_ ->
                        Expect.equal Nothing ([ 1, 2, 3 ] |> fromList |> focusedElement)
                ]
            ]
        , describe "focusNext"
            [ test "has no effect on empty list" <|
                \_ ->
                    Expect.equal Nothing (empty |> focusNext |> focusedElement)
            , test "focuses first element when there is no focus" <|
                \_ ->
                    [ 1, 2, 3 ]
                        |> fromList
                        |> focusNext
                        |> equalsNL ( [ 1, 2, 3 ], Just 1 )
            , test "focuses next element there is any" <|
                \_ ->
                    [ 1, 2, 3 ]
                        |> fromList
                        |> focusNext
                        |> focusNext
                        |> equalsNL ( [ 1, 2, 3 ], Just 2 )
            , test "has no effect when focusing last element" <|
                \_ ->
                    [ 1, 2 ]
                        |> fromList
                        |> focusNext
                        |> focusNext
                        |> focusNext
                        |> equalsNL ( [ 1, 2 ], Just 2 )
            ]
        , describe "focusPrevious"
            [ test "has no effect on empty list" <|
                \_ ->
                    Expect.equal Nothing (empty |> focusPrevious |> focusedElement)
            , test "has no effect when there is no focus" <|
                \_ ->
                    [ 1, 2, 3 ]
                        |> fromList
                        |> focusPrevious
                        |> equalsNL ( [ 1, 2, 3 ], Nothing )
            , test "focuses previous element there is any" <|
                \_ ->
                    [ 1, 2, 3 ]
                        |> fromList
                        |> focusNext
                        |> focusNext
                        |> focusPrevious
                        |> equalsNL ( [ 1, 2, 3 ], Just 1 )
            ]
        , describe "toListWithFocus"
            [ test "marks the focused element" <|
                \_ ->
                    [ 1, 2, 3 ]
                        |> fromList
                        |> focusNext
                        |> focusNext
                        |> toListWithFocus
                        |> Expect.equal [ ( 1, False ), ( 2, True ), ( 3, False ) ]
            , test "marks nothing if there is no focus" <|
                \_ ->
                    [ 1, 2, 3 ]
                        |> fromList
                        |> toListWithFocus
                        |> Expect.equal [ ( 1, False ), ( 2, False ), ( 3, False ) ]
            ]
        ]


equalsNL : ( List a, Maybe a ) -> NavegableList a -> Expectation
equalsNL ( elements, focus ) nl =
    let
        l =
            toList nl

        f =
            focusedElement nl
    in
        if l == elements then
            if f == focus then
                pass
            else
                fail <| String.concat [ "Expected ", toString f, " to equal ", toString focus ]
        else
            fail <| String.concat [ "Expected ", toString l, " to equal ", toString elements ]
