/*=================================================================================
 # fibonacci_gcd.c
 
 #  Copyright (c) 2018 ASCS Laboratory (ASCS Lab/ECE/BU)
 #  Permission is hereby granted, free of charge, to any person obtaining a copy
 #  of this software and associated documentation files (the "Software"), to deal
 #  in the Software without restriction, including without limitation the rights
 #  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 #  copies of the Software, and to permit persons to whom the Software is
 #  furnished to do so, subject to the following conditions:
 #  The above copyright notice and this permission notice shall be included in
 #  all copies or substantial portions of the Software.
 
 #  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 #  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 #  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 #  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 #  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 #  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 #  THE SOFTWARE.
 ==================================================================================*/

//#include<stdio.h>
//GCD and Fibonacci 

int gcd ( int a, int b ) {
  int c; 
  if (a == b) 
  	c = a; 
  else {
  	if(a > b)
  		a = a - b; 
  	else 
  		b = b - a; 
  	c = gcd(a,b);
  }
  return c; 
}

int fib(int n) {
    if (n <= 1) {
        return n;
    } else {
        return fib(n-1)+fib(n-2);
    }
} 

int hThread1 (int input1, int input2) {
	int output = gcd(input1, input2); 
	return output; 
}

int hThread2 (int input) {
	int output = fib(input); 
	return output; 
} 

int main(void){
    int n1 = 1989; 
    int n2 = 867;
	int n3 = 18; 
	int result1 = hThread1 (n1, n2);  
	int result2 = hThread2 (n3);   
    //printf("Thread-1 output %d Thread-2 output %d\n", result1, result2); 
	//system("pause");  
	return 0; 
}
