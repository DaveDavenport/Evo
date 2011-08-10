using GLib;
using Gdk;
using Xml;

namespace DNA
{
	public void Render(DNA.Strain strain, uchar[] pixels, uint width, uint height, uint nchan=3)
	{
		uint[] cpoints = new uint[256];
		uint stride = width*nchan;
		/* Clear */
		GLib.Memory.set(pixels, 0, stride*height);
		/* itterate over each polygon */
		foreach(unowned DNA.Polygon pol in strain.polygons)
		{
			if(pol.points == null) break;
			unowned DNA.Brush b  = pol.GetBrush();
			if(b.a < 0.01) break;
			float ba = 1-b.a;
			/* doing this outside innerloop saves me 2% */
			float br = b.r*b.a;
			float bg = b.g*b.a;
			float bb = b.b*b.a;

			uint y_min = (uint)(pol.top.y*height);
			uint y_max = (uint)(pol.bottom.y*height);
			uint swap;
			//  Loop through the rows of the image.
			for (uint y= y_min; y<y_max; y++) 
			{
				float pixely = y/(float)height;
				//  build a list of nodes.
				uint nodes=0;
				unowned DNA.Point lp = pol.last_point.data;
				foreach(unowned DNA.Point node in pol.points)
				{
					if ((node.y < pixely && lp.y >= pixely) ||  
						(lp.y < pixely && node.y>= pixely))
					{
						cpoints[nodes++]= (uint)(width*(node.x+(pixely-node.y)/(lp.y-node.y)*(lp.x-node.x))); 
					}
					lp = node;
				}
				if(nodes > 0)
				{
					//  sort the nodes, via a simple “bubble” sort.
					int i=0;
					while (i<nodes-1) {
						if (cpoints[i]>cpoints[i+1]) {
							swap=cpoints[i];
							cpoints[i]=cpoints[i+1];
							cpoints[i+1]=swap;
							if (i > 0) i--; 
						}
						else {
							i++; 
						}
					}
					//  fill the pixels between node pairs.
					for (i=0; i<nodes; i+=2)
					{
						for (uint j=cpoints[i]; j<cpoints[i+1]; j++)
						{
							uint index = y*stride+(uint)j*nchan;
							pixels[index] =   (uchar)(br +(ba)*(pixels[index]  ));
							pixels[index+1] = (uchar)(bg +(ba)*(pixels[index+1]));
							pixels[index+2] = (uchar)(bb +(ba)*(pixels[index+2]));
						}
					}
				}
			}
		}
	}
}
