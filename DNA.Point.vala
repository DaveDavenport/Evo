using GLib;
using Gdk;
using Xml;

namespace DNA
{

    /**
     * Point()
     */
    public class Point
    {
        private const int mutation_pos_x = 500;
        private const int mutation_pos_y = 500;
        public float x=0;
        public float y=0;


        public Point.from_xml(Xml.Node *node)
        {
            for(Xml.Node *iter =  node->children; iter != null; iter = iter->next)
            {
                if(iter->name == "x")
                {
                    x = (float)double.parse(iter->get_content());
                }else if (iter->name == "y")
                {
                    y = (float)double.parse(iter->get_content());
                }
            }
        }

        public void store_xml(Xml.Node *node)
        {
            Xml.Node *point = new Xml.Node(null, "point");
            Xml.Node *xnode = new Xml.Node(null, "x");
            Xml.Node *ynode = new Xml.Node(null, "y");

            xnode->set_content("%f".printf(x));
            ynode->set_content("%f".printf(y));
            point->add_child(xnode);
            point->add_child(ynode);
            node->add_child(point);
        }

        public Point.Random()
        {
            x = (float)DNA.Tool.rand.double_range(0, 1);
            y = (float)DNA.Tool.rand.double_range(0, 1);
        }

        public Point.Clone(Point p)
        {
            x = p.x;
            y = p.y;
        }
        public bool Mutate()
        {
            bool dirt = false;
            if(Tool.Mutate(mutation_pos_x))
            {
                x = (float)DNA.Tool.rand.double_range(0, 1);
                dirt =true;
            }
            if(Tool.Mutate(mutation_pos_y))
            {
                y = (float)DNA.Tool.rand.double_range(0, 1);
                dirt =true;
            }
            return dirt;
        }
    }
}
