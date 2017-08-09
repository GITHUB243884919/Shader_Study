using UnityEngine;
using System.Collections;
using System.Collections.Generic;

/// <summary>
/// 顶点
///     n * n 的格子顶点数量是 (n + 1) * (n + 1)
///     三角形数量是 (n * n) * 2
///     三角形定点数 (n * n) * 2 * 3 
///     以上是横竖相等的情况
///     还有一种 如果用n来表示顶点的个数，那么在同一个平面内，可以分割的三角形个数是：n-2;
///     这种情况 是根据顶点来的，对于上面的情况不管用了
/// 
/// LOD
///     LOD值越高，顶点数越少
/// </summary>
public class Ocean_1 : MonoBehaviour
{

    // 一片区域网格横纵数量
    public int width = 32;
    public int height = 32;

    // 区域的数量和大小
    // mesh的数量是tiles * teles
    public int tiles = 2;
    public Vector3 size = new Vector3(150f, 1f, 150f);

    // 材质
    public Material material;

    // 组成网格横纵的线条数量
    int g_height;
    int g_width;

    // 网格相关
    Vector3[] vertices; //顶点
    Vector3[] normals;  //法线
    Vector4[] tangents; //三角
    Mesh baseMesh;

    // LOD，越在靠后List的Mesh，网格越少
    int maxLOD = 4;
    List<List<Mesh>> tiles_LOD;

    // Use this for initialization
    void Start()
    {
        // 计算线条数量
        // 横竖格子的数量
        g_height = height + 1;
        g_width = width + 1;

        // LOD，Mesh所在的List的LOD List编号越小，Mesh的网格越多
        tiles_LOD = new List<List<Mesh>>();
        for (int LOD = 0; LOD < maxLOD; LOD++)
        {
            tiles_LOD.Add(new List<Mesh>());
        }

        // 生成 tiles * tiles 个mesh
        // 所有mesh是以本mono所在GameObject的中心排开的
        for (int y = 0; y < tiles; ++y)
        {
            for (int x = 0; x < tiles; ++x)
            {
                Debug.Log("创建了一片水");
                // tile * 0.5 相当于所有tile的中心
                //float cy = y - Mathf.Floor(tiles * 0.5f);
                //float cx = x - Mathf.Floor(tiles * 0.5f);
                float cy = y - (tiles * 0.5f);
                float cx = x - (tiles * 0.5f);

                // 创建一片水
                GameObject tile = new GameObject("WaterTile");
                tile.name = "tile_" + x + "_" + y;

                // 坐标以当前节点为中心
                tile.transform.parent = transform;
                tile.transform.localPosition = new Vector3(cx * size.x, 0f, cy * size.z);

                // 添加Mesh渲染组件
                tile.AddComponent<MeshFilter>();
                tile.AddComponent<MeshRenderer>().material = material;

                tile.layer = LayerMask.NameToLayer("Water");
                // 这时是把目前所有的mesh(tiles * tiles 个)都放在tiles_LOD[0]中的
                tiles_LOD[0].Add(tile.GetComponent<MeshFilter>().mesh);
            }
        }
        GenerateHeightmap();
    }

    // 初始化Mesh信息
    void GenerateHeightmap()
    {
        Mesh mesh = new Mesh();

        int y = 0;
        int x = 0;

        // 创建顶点和uv坐标
        Vector3[] vertices = new Vector3[g_height * g_width];
        Vector4[] tangents = new Vector4[g_height * g_width];
        Vector2[] uv = new Vector2[g_height * g_width];

        // uv和顶点坐标的缩放值（如果要创建width*height的网格）
        Vector2 uvScale = new Vector2(1.0f / (g_width - 1f), 1.0f / (g_height - 1f));
        // 一个格子的大小的相对值 = 1 / 格子数量
        // 一个格子的大小的绝对值 = tile大小 * (1 / 格子数量)
        Vector3 sizeScale = new Vector3(size.x / (g_width - 1f), size.y, size.z / (g_height - 1f));

        // 顶点和uv坐标一个一个排列过去，在之前MC创建方块的时候没用使用这样的方法，是每个面就对应四个顶点，很多顶点都重复了
        for (y = 0; y < g_height; ++y)
        {
            for (x = 0; x < g_width; ++x)
            {
                vertices[y * g_width + x] = Vector3.Scale(new Vector3(x, 0f, y), sizeScale);
                uv[y * g_width + x] = Vector2.Scale(new Vector2(x, y), uvScale);
            }
        }
        mesh.vertices = vertices;
        mesh.uv = uv;

        // 设置切线，暂时不清楚为什么要这么设置
        for (y = 0; y < g_height; ++y)
        {
            for (x = 0; x < g_width; ++x)
            {
                tangents[y * g_width + x] = new Vector4(1f, 0f, 0f, -1f);
            }
        }
        mesh.tangents = tangents;
        baseMesh = mesh;

        // 生成LOD对应的网格，数组越靠后，网格越大、数量越少
        for (int LOD = 0; LOD < maxLOD; ++LOD)
        {
            Vector3[] verticesLOD = new Vector3[(int)(height / System.Math.Pow(2, LOD) + 1) * (int)(width / System.Math.Pow(2, LOD) + 1)];
            Vector2[] uvLOD = new Vector2[(int)(height / System.Math.Pow(2, LOD) + 1) * (int)(width / System.Math.Pow(2, LOD) + 1)];
            int idx = 0;

            for (y = 0; y < g_height; y += (int)System.Math.Pow(2, LOD))
            {
                for (x = 0; x < g_width; x += (int)System.Math.Pow(2, LOD))
                {
                    verticesLOD[idx] = vertices[g_width * y + x];
                    uvLOD[idx++] = uv[g_width * y + x];
                }
            }

            // tiles_LOD中的网格都替换成为LOD优化过的网格
            for (int k = 0; k < tiles_LOD[LOD].Count; ++k)
            {
                Mesh meshLOD = tiles_LOD[LOD][k];
                Debug.Log("LOD " + LOD + " verticesLOD.Length = " + verticesLOD.Length);
                meshLOD.vertices = verticesLOD;
                meshLOD.uv = uvLOD;
            }
        }

        // 三角顶点信息，一个方块对应两个三角、对应六个顶点
        for (int LOD = 0; LOD < maxLOD; ++LOD)
        {
            int index = 0;
            int width_LOD = (int)(width / System.Math.Pow(2, LOD) + 1);
            int[] triangles = new int[(int)(height / System.Math.Pow(2, LOD) * width / System.Math.Pow(2, LOD)) * 6];
            for (y = 0; y < (int)(height / System.Math.Pow(2, LOD)); ++y)
            {
                for (x = 0; x < (int)(width / System.Math.Pow(2, LOD)); ++x)
                {
                    // 这边逆时针绘制了，按照以前的测试要顺时针才能看见，可能跟切线法线有关
                    triangles[index++] = (y * width_LOD) + x;
                    triangles[index++] = ((y + 1) * width_LOD) + x;
                    triangles[index++] = (y * width_LOD) + x + 1;

                    triangles[index++] = ((y + 1) * width_LOD) + x;
                    triangles[index++] = ((y + 1) * width_LOD) + x + 1;
                    triangles[index++] = (y * width_LOD) + x + 1;
                }
            }

            // 三角替换
            for (int k = 0; k < tiles_LOD[LOD].Count; ++k)
            {
                Mesh meshLOD = tiles_LOD[LOD][k];
                meshLOD.triangles = triangles;
            }
        }
    }
}