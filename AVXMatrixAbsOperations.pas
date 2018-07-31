// ###################################################################
// #### This file is part of the mathematics library project, and is
// #### offered under the licence agreement described on
// #### http://www.mrsoft.org/
// ####
// #### Copyright:(c) 2018, Michael R. . All rights reserved.
// ####
// #### Unless required by applicable law or agreed to in writing, software
// #### distributed under the License is distributed on an "AS IS" BASIS,
// #### WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// #### See the License for the specific language governing permissions and
// #### limitations under the License.
// ###################################################################

unit AVXMatrixAbsOperations;

// #####################################################
// #### Abs opertaion applied to every element in a matrix
// #####################################################

interface

{$IFDEF CPUX64}
{$DEFINE x64}
{$ENDIF}
{$IFDEF cpux86_64}
{$DEFINE x64}
{$ENDIF}
{$IFNDEF x64}

uses MatrixConst;

procedure AVXMatrixAbsAligned(Dest : PDouble; const LineWidth, Width, Height : TASMNativeInt);
procedure AVXMatrixAbsUnAligned(Dest : PDouble; const LineWidth, Width, Height : TASMNativeInt);

{$ENDIF}

implementation

{$IFNDEF x64}

{$IFDEF FPC} {$ASMMODE intel} {$S-} {$ENDIF}

const cLocSignBits4 : Array[0..3] of int64 = ($7FFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF, $7FFFFFFFFFFFFFFF);

procedure AVXMatrixAbsAligned(Dest : PDouble; const LineWidth, Width, Height : TASMNativeInt);
var iters : TASMNativeInt;
begin
asm
   mov eax, width;
   shl eax, 3;
   imul eax, -1;
   mov iters, eax;

   // helper registers for the dest pointer
   mov ecx, dest;
   sub ecx, eax;

   lea edx, cLocSignBits4;
   {$IFDEF FPC}vmovupd ymm0, [edx];{$ELSE}db $C5,$FD,$10,$02;{$ENDIF} 

   // for y := 0 to height - 1:
   mov edx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov eax, iters;
       @addforxloop:
           add eax, 128;
           jg @loopEnd;

           // prefetch data...
           //prefetchw [rcx + rax];

           // Abs:
           {$IFDEF FPC}vmovapd ymm1, [ecx + eax - 128];{$ELSE}db $C5,$FD,$28,$4C,$01,$80;{$ENDIF} 
           {$IFDEF FPC}vAndpd ymm1, ymm1, ymm0;{$ELSE}db $C5,$F5,$54,$C8;{$ENDIF} 
           {$IFDEF FPC}vmovntdq [ecx + eax - 128], ymm1;{$ELSE}db $C5,$FD,$E7,$4C,$01,$80;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm2, [ecx + eax - 96];{$ELSE}db $C5,$FD,$28,$54,$01,$A0;{$ENDIF} 
           {$IFDEF FPC}vandpd ymm2, ymm2, ymm0;{$ELSE}db $C5,$ED,$54,$D0;{$ENDIF} 
           {$IFDEF FPC}vmovntdq [ecx + eax - 96], ymm2;{$ELSE}db $C5,$FD,$E7,$54,$01,$A0;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm3, [ecx + eax - 64];{$ELSE}db $C5,$FD,$28,$5C,$01,$C0;{$ENDIF} 
           {$IFDEF FPC}vandpd ymm3, ymm3, ymm0;{$ELSE}db $C5,$E5,$54,$D8;{$ENDIF} 
           {$IFDEF FPC}vmovntdq [ecx + eax - 64], ymm3;{$ELSE}db $C5,$FD,$E7,$5C,$01,$C0;{$ENDIF} 

           {$IFDEF FPC}vmovapd ymm4, [ecx + eax - 32];{$ELSE}db $C5,$FD,$28,$64,$01,$E0;{$ENDIF} 
           {$IFDEF FPC}vandpd ymm4, ymm4, ymm0;{$ELSE}db $C5,$DD,$54,$E0;{$ENDIF} 
           {$IFDEF FPC}vmovntdq [ecx + eax - 32], ymm4;{$ELSE}db $C5,$FD,$E7,$64,$01,$E0;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       sub eax, 128;

       jz @nextLine;

       @addforxloop2:
           add eax, 16;
           jg @loopEnd2;

           {$IFDEF FPC}vmovapd xmm1, [ecx + eax - 16];{$ELSE}db $C5,$F9,$28,$4C,$01,$F0;{$ENDIF} 
           {$IFDEF FPC}vandpd xmm1, xmm1, xmm0;{$ELSE}db $C5,$F1,$54,$C8;{$ENDIF} 
           {$IFDEF FPC}vmovntdq [ecx + eax - 16], xmm1;{$ELSE}db $C5,$F9,$E7,$4C,$01,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @loopEnd2:

       sub eax, 16;
       jz @nextLine;

       {$IFDEF FPC}vmovsd xmm1, [ecx + eax];{$ELSE}db $C5,$FB,$10,$0C,$01;{$ENDIF} 
       {$IFDEF FPC}vandpd xmm1, xmm1, xmm0;{$ELSE}db $C5,$F1,$54,$C8;{$ENDIF} 
       {$IFDEF FPC}vmovsd [ecx + eax], xmm1;{$ELSE}db $C5,$FB,$11,$0C,$01;{$ENDIF} 

       @nextLine:

       // next line:
       add ecx, linewidth;

   // loop y end
   dec edx;
   jnz @@addforyloop;

   {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;
end;

procedure AVXMatrixAbsUnAligned(Dest : PDouble; const LineWidth, Width, Height : TASMNativeInt);
var iters : TASMNativeInt;

begin

asm
   mov eax, width;
   shl eax, 3;
   imul eax, -1;
   mov iters, eax;

   // helper registers for the dest pointer
   mov ecx, Dest;
   sub ecx, eax;

   lea edx, cLocSignBits4;
   {$IFDEF FPC}vmovupd ymm0, [edx];{$ELSE}db $C5,$FD,$10,$02;{$ENDIF} 

   // for y := 0 to height - 1:
   mov edx, Height;
   @@addforyloop:
       // for x := 0 to w - 1;
       // prepare for reverse loop
       mov eax, iters;
       @addforxloop:
           add eax, 128;
           jg @loopEnd;

           // prefetch data...
           //prefetchw [ecx + rax];

           // Abs:
           {$IFDEF FPC}vmovupd ymm1, [ecx + eax - 128];{$ELSE}db $C5,$FD,$10,$4C,$01,$80;{$ENDIF} 
           {$IFDEF FPC}vAndpd ymm1, ymm1, ymm0;{$ELSE}db $C5,$F5,$54,$C8;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 128], ymm1;{$ELSE}db $C5,$FD,$11,$4C,$01,$80;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm2, [ecx + eax - 96];{$ELSE}db $C5,$FD,$10,$54,$01,$A0;{$ENDIF} 
           {$IFDEF FPC}vandpd ymm2, ymm2, ymm0;{$ELSE}db $C5,$ED,$54,$D0;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 96], ymm2;{$ELSE}db $C5,$FD,$11,$54,$01,$A0;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm3, [ecx + eax - 64];{$ELSE}db $C5,$FD,$10,$5C,$01,$C0;{$ENDIF} 
           {$IFDEF FPC}vandpd ymm3, ymm3, ymm0;{$ELSE}db $C5,$E5,$54,$D8;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 64], ymm3;{$ELSE}db $C5,$FD,$11,$5C,$01,$C0;{$ENDIF} 

           {$IFDEF FPC}vmovupd ymm4, [ecx + eax - 32];{$ELSE}db $C5,$FD,$10,$64,$01,$E0;{$ENDIF} 
           {$IFDEF FPC}vandpd ymm4, ymm4, ymm0;{$ELSE}db $C5,$DD,$54,$E0;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 32], ymm4;{$ELSE}db $C5,$FD,$11,$64,$01,$E0;{$ENDIF} 
       jmp @addforxloop

       @loopEnd:

       sub eax, 128;

       jz @nextLine;

       @addforxloop2:
           add eax, 16;
           jg @loopEnd2;

           {$IFDEF FPC}vmovupd xmm1, [ecx + eax - 16];{$ELSE}db $C5,$F9,$10,$4C,$01,$F0;{$ENDIF} 
           {$IFDEF FPC}vandpd xmm1, xmm1, xmm0;{$ELSE}db $C5,$F1,$54,$C8;{$ENDIF} 
           {$IFDEF FPC}vmovupd [ecx + eax - 16], xmm1;{$ELSE}db $C5,$F9,$11,$4C,$01,$F0;{$ENDIF} 
       jmp @addforxloop2;

       @loopEnd2:

       sub eax, 16;
       jz @nextLine;

       {$IFDEF FPC}vmovsd xmm1, [ecx + eax];{$ELSE}db $C5,$FB,$10,$0C,$01;{$ENDIF} 
       {$IFDEF FPC}vandpd xmm1, xmm1, xmm0;{$ELSE}db $C5,$F1,$54,$C8;{$ENDIF} 
       {$IFDEF FPC}vmovsd [ecx + eax], xmm1;{$ELSE}db $C5,$FB,$11,$0C,$01;{$ENDIF} 

       @nextLine:

       // next line:
       add ecx, LineWidth;

   // loop y end
   dec edx;
   jnz @@addforyloop;

   {$IFDEF FPC}vzeroupper;{$ELSE}db $C5,$F8,$77;{$ENDIF} 
end;

end;


{$ENDIF}

end.
