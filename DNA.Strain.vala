using GLib;
using Gdk;
using Xml;

namespace DNA
{

    /* The complete DNA strain */
    public class Strain
    {
        public double fitness = 1;
        public uint generation = 0;
        /* posibilities */
        private const int mutation_pos_add = 200;
        private const int mutation_pos_remove = 500;

        private const int initial_polygons = 3;
        public List<DNA.Polygon> polygons;

        /**
         * Strain()
         * Creates a number of initial polygons.
         */
        public Strain()
        {
            for(int j=0; j<initial_polygons;j++)
            {
                AddPolygon(new Polygon.Random());
            }
        }

        /**
         * Make a copy
         */
        public Strain.Clone(Strain s)
        {
            foreach(unowned DNA.Polygon pol in s.polygons)
            {
                AddPolygon(new Polygon.Clone(pol));
            }
            polygons.reverse();
        }

        /**
         * Add a polygon
         */
        public void AddPolygon(Polygon a)
        {
            polygons.prepend(a);
        }

        /**
         * Remove a polygon
         */
        public void RemovePolygon(Polygon a)
        {
            unowned List<Polygon> en = polygons.find(a);
            if(en != null)
            {
                var pol = (owned)en.data;
                polygons.delete_link(en);
                pol = null;
            }
        }

        /**
         * Mutate
         */
        public bool Mutate()
        {
            bool dirt = false;
            /* Mutate Add a polygon */
            if(DNA.Tool.Mutate(mutation_pos_add))
            {
                AddPolygon(new Polygon.Random());
                dirt = true;
            }
            /* Mutate each polygon */
            List<Polygon> remove_list = null;
            foreach(unowned Polygon pol in polygons)
            {
                /* Check if this polygon is removed, otherwise mutate */
                if(DNA.Tool.Mutate(mutation_pos_remove))
                {
                    remove_list.prepend(pol);
                    dirt = true;
                }
                else
                {
                    if(pol.Mutate())
                    {
                        dirt = true;
                    }
                }
            }
            /* Actually remove the polygons */
            foreach(unowned Polygon pol in remove_list)
            {
                RemovePolygon(pol);
            }
            /* set dirty */
            return dirt;
        }
        /**
         * print
         */
        public void print()
        {
            GLib.debug("Polygons: %u", polygons.length());
            uint points=0;
            foreach(unowned Polygon p in polygons)
            {
                points+= p.points.length();
            }
            GLib.debug("Points: %u\n", points);
        }

        public void store_xml(string xml_file, uint generation)
        {
            Xml.Doc doc = new Xml.Doc(null);
            Xml.Node *root = new Xml.Node(null, "strain");
            Xml.Node *fitn = new Xml.Node(null, "fitness");
            Xml.Node *genr = new Xml.Node(null, "generation");
            fitn->set_content("%f".printf(fitness));
            genr->set_content("%u".printf(generation));
            foreach(unowned Polygon p in polygons)
            {
                p.store_xml(root);
            }

            root->add_child(fitn);
            root->add_child(genr);
            doc.set_root_element(root);
            doc.save_format_file(xml_file,1);
        }
        /**
         * Strain.from_file(string file)
         */
        public Strain.from_file(string xml_file)
        {
            Xml.Doc doc = Xml.Parser.parse_file(xml_file);
            Xml.Node *root = doc.get_root_element();
            for(Xml.Node *iter =  root->children; iter != null; iter = iter->next)
            {
                if(iter->name == "polygon")
                {
                    var pol = new Polygon.from_xml(iter);
                    AddPolygon(pol);
                }
                else if (iter->name == "fitness")
                {
                    fitness = double.parse(iter->get_content());
                }else if (iter->name == "generation")
                {
                    generation = (uint)int.parse(iter->get_content());
                }
            }
            polygons.reverse();
        }
    }

}
