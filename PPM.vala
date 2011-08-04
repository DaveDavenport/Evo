using GLib;
using Gdk;
using Xml;

namespace PPM
{
	public void Write(DNA.Strain strain,string filename, uint width, uint height)
	{
     	uchar[width*height*3] pixels = new uchar[800*800*3];
        DNA.Render(strain, pixels, width, height,3);
		GLib.FileStream fs = GLib.FileStream.open(filename, "w");
    	fs.printf("P6\n%u %u %u\n", width, height, 255);
    	for(uint i=0; i < height; i++)
   		{
        	for(uint j=0; j<width*3;j+=3)
       		 {
            	fs.putc((char)pixels[i*width*3+j]);
            	fs.putc((char)pixels[i*width*3+j+1]);
            	fs.putc((char)pixels[i*width*3+j+2]);
        	}
    	}
    	fs = null;
	}

}
