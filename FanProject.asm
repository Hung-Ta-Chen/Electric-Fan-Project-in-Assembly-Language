ORG 0000H
AJMP WAIT
ORG 0050H

SPEED_FACTOR EQU R0

WAIT:
//P1 作為開關，以輪詢方式查看 P1 是否變為 1
//變為 1 則跳到下一階段執行動作
    MOV A, P1
    ANL A, #00000001B
    CJNE A, #00000001B, WAIT
    AJMP START

START:
    MOV A, #00110011B //將第一個狀態存入 A

//以 2 激磁方式使馬達轉動
ROTATE: 
    ACALL SET_SPEED //設定轉速大小
    ACALL SET_MODE //確認是否有設定定時
    MOV P0,A //將狀態輸出至馬達
    RL A //改變狀態，左旋為順時針
    MOV R1, A
    ACALL DELAY //呼叫 delay 給予緩衝

    MOV A, P1 //確認開關沒被關掉
    ANL A, #00000001B
    CJNE A, #00000001B, WAIT
    MOV A, R1
    AJMP ROTATE


//根據哪個指撥開關被按下，調整 DELAY 時間以得到適當的轉速
SET_SPEED:
    JB P1.7, FASTEST
    JB P1.6, FASTEST
    JB P1.5, MEDIUM
    JB P1.4, MEDIUM
    JB P1.3, SLOW
    JB P1.2, SLOW
    JB P1.1, SLOWEST
    JB P1.0, SLOWEST


FASTEST:
    MOV SPEED_FACTOR, #60
    RET

MEDIUM:
    MOV SPEED_FACTOR, #120
    RET

SLOW:
    MOV SPEED_FACTOR, #180
    RET

SLOWEST:
    MOV SPEED_FACTOR, #240
    RET

//當定時開關被按下則根據按下的開關進入對應的定時模式
SET_MODE:
    JB P2.4, TEN_MIN
    JB P2.3, FIVE_MIN
    JB P2.2, THREE_MIN
    JB P2.1, TWO_MIN
    JB P2.0, ONE_MIN
    RET

ONE_MIN:
    MOV R2, #9
    AJMP COUNT_1

TWO_MIN:
    MOV R2, #17
    AJMP COUNT_1

THREE_MIN:
    MOV R2, #25
    AJMP COUNT_1

FIVE_MIN:
    MOV R2, #41
    AJMP COUNT_1

TEN_MIN:
    MOV R2, #82
    AJMP COUNT_1


COUNT_1:
    DJNZ R2, DELAYL_1
    AJMP DELAY_END_1
DELAYL_1:
    ACALL SET_SPEED
    MOV P0,A //將狀態輸出至馬達
    RL A
    MOV R1, A //改變狀態，左旋為順時針
    ACALL DELAY //呼叫 delay 給予緩衝
    MOV A, R1
    MOV R3, #136

DELAYL1_1:
    ACALL SET_SPEED
    MOV P0,A //將狀態輸出至馬達
    RL A
    MOV R1, A //改變狀態，左旋為順時針
    ACALL DELAY //呼叫 delay 給予緩衝
    MOV A, R1
    MOV R4, #5

DELAYL2_1:
    ACALL SET_SPEED
    MOV P0,A //將狀態輸出至馬達
    RL A
    MOV R1, A //改變狀態，左旋為順時針
    ACALL DELAY //呼叫 delay 給予緩衝
    MOV A, R1
    MOV R5, #5

DELAYL3_1:
    ACALL SET_SPEED
    MOV P0,A //將狀態輸出至馬達
    RL A
    MOV R1, A //改變狀態，左旋為順時針
    ACALL DELAY //呼叫 delay 給予緩衝
    MOV A, R1

    DJNZ R5 , DELAYL3_1
    DJNZ R4, DELAYL2_1
    DJNZ R3, DELAYL1_1
    AJMP COUNT_1


DELAY_END_1:
    LJMP LOOP1


LOOP1:
    MOV P0, #11110111B //將 11110111 輸出至鍵盤，開始掃描
    //（從最上方一列開始）
    MOV R2, #0 //R2 紀錄目前掃描過的列數

NEXT1:
    MOV A, P3 //讀取按鍵掃描狀態
    ANL A, #0FH //和 00001111 作 AND 以保留較低的四個 bit
    CJNE A, #0FH, OUT1 //若保留的四個 bit 等於 1111 即代表沒有輸入
                       //不等於的話代表有讀到輸入，跳到 OUT1
    MOV A, P0 //將輸出至鍵盤的值右旋，代表掃描下面一列
    RR A
    MOV P0, A
    INC R2 //R2 加一，代表剛掃完一列
    CJNE R2, #5, NEXT1 //如果還沒掃滿四次就繼續掃
    SJMP LOOP1 //否則重新開始

//確認按鍵確實被按下
OUT1:
    ACALL DELAY_20 //先延遲 20 秒以避開開關彈跳
    MOV A, P3 //重新從鍵盤讀值一次，如果有輸入的話則回到一開始的 WAIT
    ANL A, #0FH
    CJNE A, #0FH, BACK
    SJMP LOOP1 //沒有的話重新回去掃描

BACK:
    MOV A, #00110011B
    RET

DELAY:
    MOV R6,#85
DELAY1:
    MOV A, SPEED_FACTOR
    MOV R7,A
DELAY2:
    DJNZ R7,DELAY2
    DJNZ R6,DELAY1
    RET
DELAY_20:
    MOV R6, #0FFH
DELAY1_20:
    MOV R7, #03FH
DELAY2_20:
    DJNZ R7, DELAY2_20
    DJNZ R6, DELAY1_20
    RET

    
END