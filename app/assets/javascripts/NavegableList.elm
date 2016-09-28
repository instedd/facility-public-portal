module NavegableList
    exposing
        ( NavegableList
        , empty
        , fromList
        , toList
        , toListWithFocus
        , focusedElement
        , focusNext
        , focusPrevious
        )


type alias NavegableList a =
    { beforeFocus : List a
    , focusedElement : Maybe a
    , afterFocus : List a
    }


empty : NavegableList a
empty =
    fromList []


fromList : List a -> NavegableList a
fromList l =
    { beforeFocus = l
    , focusedElement = Nothing
    , afterFocus = []
    }


construct : ( List a, Maybe a, List a ) -> NavegableList a
construct ( beforeFocus, focusedElement, afterFocus ) =
    { beforeFocus = beforeFocus
    , focusedElement = focusedElement
    , afterFocus = afterFocus
    }


toList : NavegableList a -> List a
toList { beforeFocus, focusedElement, afterFocus } =
    let
        tail =
            focusedElement
                |> Maybe.map (\x -> x :: afterFocus)
                |> Maybe.withDefault afterFocus
    in
        beforeFocus ++ tail


toListWithFocus : NavegableList a -> List ( a, Bool )
toListWithFocus { beforeFocus, focusedElement, afterFocus } =
    let
        markFalse =
            \x -> ( x, False )

        focusPart =
            focusedElement |> Maybe.map (\x -> [ ( x, True ) ]) |> Maybe.withDefault []
    in
        List.map markFalse beforeFocus ++ focusPart ++ List.map markFalse afterFocus


focusedElement : NavegableList a -> Maybe a
focusedElement nl =
    nl.focusedElement


focusNext : NavegableList a -> NavegableList a
focusNext nl =
    case ( nl.beforeFocus, nl.focusedElement, nl.afterFocus ) of
        ( _, Just x, [] ) ->
            nl

        ( _, Just x, h :: t ) ->
            { beforeFocus = nl.beforeFocus ++ [ x ]
            , focusedElement = Just h
            , afterFocus = t
            }

        ( [], Nothing, [] ) ->
            nl

        ( [], Nothing, h :: t ) ->
            { beforeFocus = []
            , focusedElement = Just h
            , afterFocus = t
            }

        ( h :: t, Nothing, _ ) ->
            { beforeFocus = []
            , focusedElement = Just h
            , afterFocus = t ++ nl.afterFocus
            }


focusPrevious : NavegableList a -> NavegableList a
focusPrevious nl =
    case ( nl.beforeFocus, nl.focusedElement, nl.afterFocus ) of
        ( [], _, _ ) ->
            nl

        ( _ :: _, Nothing, _ ) ->
            nl

        ( _ :: _, Just x, _ ) ->
            case List.reverse nl.beforeFocus of
                last :: revInit ->
                    { beforeFocus = List.reverse revInit
                    , focusedElement = Just last
                    , afterFocus = x :: nl.afterFocus
                    }

                _ ->
                    -- can't happen
                    nl
