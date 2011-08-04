using GLib;
using Gdk;
using Xml;

namespace DNA
{
/*
	public void Render(DNA.Strain strain, uchar[] pixels, uint width, uint height, uint nchan=3)
	{
    uint stride = width*nchan;
    // Clear 
    GLib.Memory.set(pixels, 0, stride*height);
    // itterate over each polygon 
    foreach(unowned DNA.Polygon pol in strain.polygons)
    {
        unowned DNA.Brush b  = pol.GetBrush();
        unowned DNA.Point p0 = pol.points.nth_data(0);
        unowned DNA.Point p1 = pol.points.nth_data(1);
        unowned DNA.Point p2 = pol.points.nth_data(2);

        float v0x = p2.x - p0.x;
        float v0y = p2.y - p0.y;
        float dot00 = v0x*v0x + v0y*v0y;

        float v1x = p1.x - p0.x;
        float v1y = p1.y - p0.y;

        float dot01 = v0x*v1x + v0y*v1y;
        float dot11 = v1x*v1x + v1y*v1y;

        float invdenom = 1.0f / (float)(dot00*dot11 - dot01*dot01);
        uint y_max = (uint)(pol.bottom.y*height);
        uint x_max = (uint)(pol.bottom.x*stride);


        for(uint i=(uint)(pol.top.y*height); i < y_max; i++)
        {
            uint uy = i*stride;
            // Make sure j is multiple of 4.
            for(uint j=nchan*((uint)(pol.top.x*width)); j<x_max;j+=nchan)
            {
                float v2x =  j/(float)(stride) - p0.x;
                float v2y =  i/(float)(height) - p0.y;
                float dot02 = v0x*v2x + v0y*v2y;
                float dot12 = v1x*v2x + v1y*v2y;

                float u = (dot11*dot02 - dot01*dot12) * invdenom;
                if( u > 0 )
                {
                    float v = (dot00*dot12 - dot01*dot02) * invdenom;
                    if( v > 0 )
                    {
                        if(u + v < 1)
                        {
                            uint index = uy+j;
                            pixels[index] =   (uchar)((b.r*b.a) +(1-b.a)*(pixels[index]  ));
                            pixels[index+1] = (uchar)((b.g*b.a) +(1-b.a)*(pixels[index+1]));
                            pixels[index+2] = (uchar)((b.b*b.a) +(1-b.a)*(pixels[index+2]));
                        }
                    }
                }
            }
        }
    }
    */
	public void Render(DNA.Strain strain, uchar[] pixels, uint width, uint height, uint nchan=3)
	{
		uint stride = width*nchan;
		/* Clear */
		GLib.Memory.set(pixels, 0, stride*height);
		/* itterate over each polygon */
		foreach(unowned DNA.Polygon pol in strain.polygons)
		{
			unowned DNA.Brush b  = pol.GetBrush();

			uint y_max = (uint)(pol.bottom.y*height);
			uint x_max = (uint)(pol.bottom.x*stride);

			for(uint i=(uint)(pol.top.y*height); i < y_max; i++)
			{
				uint uy = i*stride;
				float y = i/(float)height;
				for(uint j=((uint)(pol.top.x*width)); j<x_max;j++)
				{
					float x = j/(float)width;
					if(pol.points == null) break;
					unowned List<DNA.Point> iter = pol.points.first();
					uint crossing = 0;
					unowned DNA.Point lp = pol.last_point.data;
					do{
						if(iter == null) break;
						unowned DNA.Point p = iter.data;

						float denom = 1.0f/((lp.y-p.y)*(1-x));
						float tmp1 = lp.x*p.y-lp.y*p.x;
						float tmp2 = (x*y-y);
						float inter_x = (tmp1*(x-1)-(lp.x-p.x)*tmp2)*denom;
						bool inbetween = (y >= float.min(lp.y, p.y)) && (y <  float.max(lp.y, p.y)) && (inter_x >  x);
						if(inbetween) crossing++;

						iter = iter.next;
						lp = p;
					}
					while(iter != null);
					if(((crossing&1) != 0)) {
						uint index = uy+j*nchan;
						pixels[index] =   (uchar)((b.r*b.a) +(1-b.a)*(pixels[index]  ));
						pixels[index+1] = (uchar)((b.g*b.a) +(1-b.a)*(pixels[index+1]));
						pixels[index+2] = (uchar)((b.b*b.a) +(1-b.a)*(pixels[index+2]));
					}

				}
			}
		}
	}

}
