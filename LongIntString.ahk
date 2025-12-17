#Requires AutoHotkey v2.0.0+
;==============================================================
; LongIntString — BigInteger-style integer math using string operations
;
; GitHub: https://github.com/SevenKeyboard/long-int-string
; Author: SevenKeyboard Ltd. (2025)
; License: The Unlicense
;
; Refactored from:
;   BigInteger-Calculation with AHK
;     https://www.autohotkey.com/board/topic/3474-biginteger-calculation-with-ahk/
;==============================================================

/*
Example Usage:
    fLS:="-7017219693882163320913724011876682256246082153258011700655963171016628608418859376410323198231558064"
    sLS:="3841946826050076305519988531947968598725793636630200189916311837137669434790218213023109767580774728"

    ;  fLS + sLS
    msgbox(LongIntString.add(fLS, sLS))     ;  "-3175272867832087015393735479928713657520288516627811510739651333878959173628641163387213430650783336"
    ;  fLS - sLS
    msgbox(LongIntString.sub(fLS, sLS))     ;  "-10859166519932239626433712543824650854971875789888211890572275008154298043209077589433432965812332792"
    ;  fLS × sLS
    msgbox(LongIntString.mult(fLS, sLS))    ;  "-26959784930606665426089824998765653932604240234561315623445313951947854123710025564989047122488926958172576083477933086012567723813098305748825550050038047870165962194091779450600822751034303635806592"
*/

class VersionManager_LongIntString
{
    static _ := this._init()
    static _init()    {
        global
        LONGINTSTRING_VERSION := "1.0.0"
    }
}
class LongIntString
{
    /*
    Removes leading zeros from a LongInt string.
    If the string has a leading minus sign, it is preserved.
      -0000123 => -123
      00985    => 985
    */
    static _removeLeadingZeros(&longString)    {
        /*
        longString:=regExReplace(longString,"sD`a)^(-?)0+(.*)$","${1}${2}")
        if (longString=="" || longString=="-")
            longString:="0"
        else if (longString=="-0")
            longString:="0"
        */
        if (longString=="" || longString=="-")    {
            longString:="0"
            return
        }
        longString:=regExReplace(longString,"^(-?)0+(?=\d)","${1}")
        if (longString=="-0")
            longString:="0"
    }
    ;------------------------------------------------------------
    /*
    Compares two integer strings (including an optional leading minus sign).
    Leading zeros are removed by default to make comparison reliable.
    Returns:
      -1 if first  < second
       0 if first == second
       1 if first  > second
    If either string is empty, it is treated as 0.
    */
    static _stringCompare(&firstLongString, &secondLongString)    {
        this._removeLeadingZeros(&firstLongString)
        ,this._removeLeadingZeros(&secondLongString)
        ,fSize:=strLen(firstLongString)
        ,sSize:=strLen(secondLongString)
        ,fCh:=subStr(firstLongString,1,1)
        ,sCh:=subStr(secondLongString,1,1)
        if (fCh=="-" && sCh!=="-")    {
            retVal:=-1
        }  else if (sCh=="-" && fCh!=="-")    {
            retVal:=1
        }  else  {
            if (fSize>sSize)    {
                retVal:=(fCh=="-" && sCh=="-"?-1:1)
            }  else if (sSize>fSize)    {
                retVal:=(fCh=="-" && sCh=="-"?1:-1)
            }  else if (sSize==fSize)    {
                retVal:=0 ;  Assume no difference until a mismatching digit is found.
                loop (sSize)    {
                    dig1:=subStr(firstLongString,A_Index,1)
                    ,dig2:=subStr(secondLongString,A_Index,1)
                    if (dig1!==dig2)    {  ;  Found a different digit.
                        if (dig2<dig1)
                            retVal:=(fCh=="-" && sCh=="-"?-1:1)
                        else if (dig1<dig2)
                            retVal:=(fCh=="-" && sCh=="-"?1:-1)
                        break
                    }
                } 
            }
        }
        return retVal
    }
    ;------------------------------------------------------------
    /*
    Returns 1 if longString starts with a minus sign; otherwise returns 0.
    */
    static _isNeg(&longString)    {
        return (subStr(longString,1,1)=="-")
    }
    ;------------------------------------------------------------
    /*
    Returns the absolute-value form of longString by removing any leading minus sign.
    */
    static _abs(&longString)    {
        return (subStr(longString,1,1)=="-"
            ?subStr(longString,2)
            :longString)
    }
    ;------------------------------------------------------------
    /*
    Pads both strings with leading zeros so they end up with the same length.
    A leading minus sign is preserved. Adds 3 extra reserve zeros.
    */
    static _makeFitLength(&firstLongString, &secondLongString)    {
        this._removeLeadingZeros(&firstLongString)
        ,this._removeLeadingZeros(&secondLongString)
        ,fCh:=subStr(firstLongString,1,1)
        ,sCh:=subStr(secondLongString,1,1)
        ;  Remove minus first (if present). 
        if (fCh=="-")
            firstLongString:=subStr(firstLongString,2)
        if (sCh=="-")
            secondLongString:=subStr(secondLongString,2)
        ls1Size:=strLen(firstLongString)
        ,ls2Size:=strLen(secondLongString)
        ,maxi:=max(ls1Size,ls2Size)
        /*
        l1Diff:=maxi-ls1Size+3
        ,l2Diff:=maxi-ls2Size+3
        loop (l1Diff)
            firstLongString:="0" firstLongString
        loop (l2Diff)
            secondLongString:="0" secondLongString
        */
        firstLongString:=format("{:0" maxi+3 "}",firstLongString . "")
        ,secondLongString:=format("{:0" maxi+3 "}",secondLongString . "")
        ;  Put back the minus sign (if there was one).
        if (fCh=="-")
            firstLongString:="-" firstLongString
        if (sCh=="-")
            secondLongString:="-" secondLongString
    }
    ;------------------------------------------------------------
    /*
    Subtracts secondLongString from firstLongString and always returns a positive result.
    Assumptions (required):
      - Both inputs are positive-only strings (no minus sign).
      - Leading zeros are already removed.
      - firstLongString >= secondLongString (so the result is non-negative).
    Example: 1000 - 456 = 544
    Internal use only; called by the public add/sub functions.
    */
    static _absSub(&firstLongString, &secondLongString)    {
        rem:=0
        ,resultString:=""
        ,maxLength:=strLen(firstLongString)
        loop (maxLength)    {
            value1:=subStr(firstLongString,maxLength+1-A_index,1)
            ,value2:=subStr(secondLongString,maxLength+1-A_index,1)
            ,sum:=value1-(value2+rem)
            ,rem:=(9-sum)//10
            ,erg:=mod((sum+10),10)
            ,resultString:=erg . resultString
        }
        return resultString
    }
    ;------------------------------------------------------------
    /*
    Subtracts secondLongString from firstLongString and returns the result as a string.
    Supports both positive and negative long-integer strings.
    */
    static sub(firstLongString, secondLongString)    {
        ;  Remember the sign.
        fIsNeg:=this._isNeg(&firstLongString)
        ,sIsNeg:=this._isNeg(&secondLongString)
        ;  Remove the sign on work strings.
        ,ws1:=this._abs(&firstLongString)
        ,ws2:=this._abs(&secondLongString)
        ;  Compare absolute values.
        ,absCompi:=this._stringCompare(&ws1,&ws2)
        ;  Make strings the same length by adding leading zeros.
        ,this._makeFitLength(&ws1,&ws2)
        switch
        {
            case (!fIsNeg && sIsNeg): ;  First pos, second neg:  x - -y => (x + y)
                wsResult:=this._absAdd(&ws1,&ws2)
            case (fIsNeg && !sIsNeg): ;  First neg, second pos: -x - y => -(x + y)
                wsResult:="-" . this._absAdd(&ws1,&ws2)
            case (fIsNeg && sIsNeg): ;  Both negative
                switch (absCompi)
                {
                    case 0:     return "0"                              ;  Same absolute value: -5 - -5 => 0 
                    case 1:     wsResult:="-" . this._absSub(&ws1,&ws2) ;  -1000 - -20 = -980 => negative
                    case -1:    wsResult:=this._absSub(&ws2,&ws1)       ;  -20 - -1000 = +980 => positive
                }
            case (!fIsNeg && !sIsNeg): ;  Both positive                  
                switch (absCompi)
                {
                    case 0:     return "0"                              ;  Same absolute value: 5 - 5 => 0
                    case 1:     wsResult:=this._absSub(&ws1,&ws2)       ;  1000 - 20 = 980 => positive
                    case -1:    wsResult:="-" . this._absSub(&ws2,&ws1) ;  20 - 1000 = -980 => negative
                }
        }
        this._removeLeadingZeros(&wsResult)
        return wsResult
    }
    ;------------------------------------------------------------
    /*
    Adds firstLongString and secondLongString.
    Assumptions (required):
      - Both inputs have their minus signs removed.
      - Both inputs are already padded using this._makeFitLength().
    Internal use only; called by the public add/sub functions.
    */
    static _absAdd(&firstLongString, &secondLongString)    {
        rem:=0
        ,resultString:=""
        ,maxLength:=strLen(firstLongString)
        loop (maxLength)    {
            value1:=subStr(firstLongString,maxLength+1-A_index,1)
            ,value2:=subStr(secondLongString,maxLength+1-A_index,1)
            ,sum:=value1+Value2+rem
            ,erg:=mod(sum,10)
            ,rem:=sum//10
            ,resultString:=erg . resultString
        }
        return resultString
    }
    ;------------------------------------------------------------
    /*
    Adds two long-integer strings and returns the result as a string.
    Supports both positive and negative values.
    */
    static add(firstLongString, secondLongString)    {
        ;  Remember the sign.
        fIsNeg:=this._isNeg(&firstLongString)
        ,sIsNeg:=this._isNeg(&secondLongString)
        ;  Remove the sign on work strings.
        ,ws1:=this._abs(&firstLongString)
        ,ws2:=this._abs(&secondLongString)
        ;  Compare absolute values.
        ,absCompi:=this._stringCompare(&ws1,&ws2)
        ;  Make strings the same length by adding leading zeros.
        this._makeFitLength(&ws1,&ws2)
        switch
        {
            case (!fIsNeg && !sIsNeg): ;  Both positive => positive result
                wsResult:=this._absAdd(&ws1,&ws2)
            case (fIsNeg && sIsNeg): ;  Both negative => negative result
                wsResult:="-" . this._absAdd(&ws1,&ws2)
            case (fIsNeg && !sIsNeg): ;  First negative, second positive
                switch (absCompi)
                {
                    case 0:     return "0"                              ;  -5 + 5 => 0
                    case 1:     wsResult:="-" . this._absSub(&ws1,&ws2) ;  -1000 + 20 = -980 => negative
                    case -1:    wsResult:=this._absSub(&ws2,&ws1)       ;  -20 + 1000 = +980 => positive
                }
            case (!fIsNeg && sIsNeg): ;  First positive, second negative
                switch (absCompi)
                {
                    case 0:     return "0"                              ;  5 + -5 => 0
                    case 1:     wsResult:=this._absSub(&ws1,&ws2)       ;  1000 + -20 = 980 => positive
                    case -1:    wsResult:="-" . this._absSub(&ws2,&ws1) ;  20 + -1000 = -980 => negative
                }
        }
        this._removeLeadingZeros(&wsResult)
        return wsResult
    }
    ;------------------------------------------------------------
    /*
    Multiplies firstLongString and secondLongString and returns the result as a string.
    Supports both positive and negative values.
    */
    static mult(firstLongString, secondLongString)    {
        resultString:="0"
        ;  Remember the sign.
        ,fIsNeg:=this._isNeg(&firstLongString)
        ,sIsNeg:=this._isNeg(&secondLongString)
        ;  Remove the sign on work strings.
        ,ws1:=this._abs(&firstLongString)
        ,ws2:=this._abs(&secondLongString)
        ;  Compare absolute values.
        ,absCompi:=this._stringCompare(&ws1,&ws2)
        if (absCompi==1) ;  Multiply bigger number by smaller number.
            dummy:=ws1, ws1:=ws2, ws2:=dummy
        loop1Count:=strLen(ws1)
        ,loop2Count:=strLen(ws2)
        loop (loop1Count)    {
            outLoopCounter:=A_Index
            ,help:=""
            ,rem:=0
            loop (loop2Count)    {
                inLoopCounter:=A_Index
                ,rightVal:=subStr(ws2,-inLoopCounter,1)
                ,leftVal:=subStr(ws1,-outLoopCounter,1)
                ,mulRes:=(leftVal*rightVal)+rem
                ,rem:=mulRes//10
                ,rest:=mod(mulRes,10)
                ,help:=rest . help
            }     
            help:=rem . help ;  Carry at the end (verify if this is correct).
            ,zeroAdd:=outLoopCounter-1
            loop (zeroAdd)
                help.="0"
            this._makeFitLength(&resultString,&help)
            ,resultString:=this._absAdd(&resultString,&help)
        }
        this._removeLeadingZeros(&resultString)
        if ((fIsNeg!==sIsNeg) && resultString!=="0")
            return "-" . resultString
        return resultString
    }
}