/*
    THIS CLASS IS FOR COMPLEX CACULATION
*/

public class Complex
{
  public double x; // Used to represent real part
  public double y; // Used to represent imaginary part
  
  // Initilize Complex
  Complex(double x, double y) {
    this.x = x;
    this.y = y;
  }
  
  // Minus operation
  Complex minus(Complex b) {
    Complex newComplex = new Complex(0.0, 0.0);
    newComplex.x = this.x - b.x;
    newComplex.y = this.y - b.y;
    return newComplex;
  }
  
  // Add operation
  Complex add(Complex b) {
    Complex newComplex = new Complex(0.0, 0.0);
    newComplex.x = this.x + b.x;
    newComplex.y = this.y + b.y;
    return newComplex;
  }
  
  // Multiply operation
  Complex multi(Complex b) {
    Complex newComplex = new Complex(0.0, 0.0);
    newComplex.x = this.x * b.x - this.y * b.y;
    newComplex.y = this.x * b.y + this.y * b.x;
    return newComplex;
  }
  
}