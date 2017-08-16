using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class Mirror : MonoBehaviour 
{
    private static bool s_InsideWater;
    private Dictionary<Camera, Camera> m_ReflectionCameras = new Dictionary<Camera, Camera>(); // Camera -> Camera table
    private RenderTexture m_ReflectionTexture;
    private int m_OldReflectionTextureSize;
    public int textureSize = 256;
    public bool disablePixelLights = true;
    public float clipPlaneOffset = 0.07f;
    public LayerMask reflectLayers = -1;
	void Start ()
    {

	}

	void Update () 
    {

	}

    public void OnWillRenderObject()
    {
        Camera cam = Camera.current;
        //Camera cam = Camera.main;
        if (!cam)
        {
            return;
        }

        // Safeguard from recursive water reflections.
        if (s_InsideWater)
        {
            return;
        }
        s_InsideWater = true;

        Camera reflectionCamera;
        CreateMirrorCamera(cam, out reflectionCamera);
        Vector3 pos = transform.position;
        Vector3 normal = transform.up;
        int oldPixelLightCount = QualitySettings.pixelLightCount;
        if (disablePixelLights)
        {
            QualitySettings.pixelLightCount = 0;
        }
        UpdateCameraModes(cam, reflectionCamera);

        //if (mode >= WaterMode.Reflective)
        {
            // Reflect camera around reflection plane
            // 获得反射纹理的几个流程
            //     1.反射摄像机的反射矩阵
            //     2.反射摄像机的投影矩阵
            //     3.反射摄像机x旋转下
            //     4.渲染到纹理
            // 通过构建发射平面进而构建反射矩阵，并将反射矩阵设置成反射摄像机的worldToCameraMatrix
            //     反射平面： 所在GameObject的法线（向上）和点（就选所在GameObject的位置）

            float d = -Vector3.Dot(normal, pos) - clipPlaneOffset;
            Vector4 reflectionPlane = new Vector4(normal.x, normal.y, normal.z, d);
            Matrix4x4 reflection = Matrix4x4.zero;
            CalculateReflectionMatrix(ref reflection, reflectionPlane);
            Vector3 oldpos = cam.transform.position;
            Vector3 newpos = reflection.MultiplyPoint(oldpos);
            reflectionCamera.worldToCameraMatrix = cam.worldToCameraMatrix * reflection;

            // Setup oblique projection matrix so that near plane is our reflection
            // plane. This way we clip everything below/above it for free.
            // 投影矩阵
            // 参考http://www.cnblogs.com/wantnon/p/4569096.html
            //     也就是说，oblique投影矩阵与普通投影矩阵（透视投影矩阵和正交投影矩阵）的差别是：普通投影矩阵所描述的视截体近平面与锥轴垂直，
            //     而oblique投影矩阵所描述的视截体近平面是斜的（与锥轴不垂直）。
            //     由于水面是反射面，所以渲染反射图象时必须以视截体被水面所截的截面作为视口，即“斜视口”，
            //     所以必须将反射相机转化成oblique投影模式。
            //     reflectionCamera.projectionMatrix = cam.CalculateObliqueMatrix(clipPlane)就是干这个事儿。
            Vector4 clipPlane = CameraSpacePlane(reflectionCamera, pos, normal, 1.0f);
            reflectionCamera.projectionMatrix = cam.CalculateObliqueMatrix(clipPlane);

            reflectionCamera.cullingMask = ~(1 << 4) & reflectLayers.value; // never render water layer
            reflectionCamera.targetTexture = m_ReflectionTexture;
            bool oldCulling = GL.invertCulling;
            GL.invertCulling = !oldCulling;
            reflectionCamera.transform.position = newpos;
            Vector3 euler = cam.transform.eulerAngles;
            //反射是镜像，x转一下
            reflectionCamera.transform.eulerAngles = new Vector3(-euler.x, euler.y, euler.z);
            Debug.Log("Pre reflection.Camera.Render() Camera.current = " + Camera.current.gameObject.GetInstanceID() +
                " main " + Camera.main.gameObject.GetInstanceID() + " " + Time.realtimeSinceStartup);
            reflectionCamera.Render();
            Debug.Log("Post reflection.Camera.Render()  Camera.current = " + Camera.current.gameObject.GetInstanceID() +
                " main " + Camera.main.gameObject.GetInstanceID() + " " + Time.realtimeSinceStartup);
            reflectionCamera.transform.position = oldpos;
            GL.invertCulling = oldCulling;
            GetComponent<Renderer>().sharedMaterial.SetTexture("_ReflectionTex", m_ReflectionTexture);
        }

        if (disablePixelLights)
        {
            QualitySettings.pixelLightCount = oldPixelLightCount;
        }

        s_InsideWater = false;
    }

    void CreateMirrorCamera(Camera currentCamera, out Camera reflectionCamera)
    {
        Debug.Log("CreateWaterObjects " + Time.realtimeSinceStartup);

        reflectionCamera = null;

        //if (mode >= WaterMode.Reflective)
        {
            // Reflection render texture
            if (!m_ReflectionTexture || m_OldReflectionTextureSize != textureSize)
            {
                if (m_ReflectionTexture)
                {
                    DestroyImmediate(m_ReflectionTexture);
                }
                m_ReflectionTexture = new RenderTexture(textureSize, textureSize, 16);
                m_ReflectionTexture.name = "__WaterReflection" + GetInstanceID();
                m_ReflectionTexture.isPowerOfTwo = true;
                m_ReflectionTexture.hideFlags = HideFlags.DontSave;
                m_OldReflectionTextureSize = textureSize;
            }

            // Camera for reflection
            m_ReflectionCameras.TryGetValue(currentCamera, out reflectionCamera);
            if (!reflectionCamera) // catch both not-in-dictionary and in-dictionary-but-deleted-GO
            {
                // 创建一个带Camera和Skybox的GameObject
                GameObject go = new GameObject("Water Refl Camera id" + GetInstanceID() + " for " + currentCamera.GetInstanceID(), typeof(Camera), typeof(Skybox));
                reflectionCamera = go.GetComponent<Camera>();
                reflectionCamera.enabled = false;
                reflectionCamera.transform.position = transform.position;
                reflectionCamera.transform.rotation = transform.rotation;
                reflectionCamera.gameObject.AddComponent<FlareLayer>();
                go.hideFlags = HideFlags.HideAndDontSave;
                m_ReflectionCameras[currentCamera] = reflectionCamera;
                Debug.Log("m_ReflectionCameras.Count = " + m_ReflectionCameras.Count + " "
                    + go.GetInstanceID() + " "
                    + currentCamera.GetInstanceID() + " " + currentCamera.tag + " "
                    + GetInstanceID() + " "
                    + Time.realtimeSinceStartup);
            }
        }
    }

    void UpdateCameraModes(Camera src, Camera dest)
    {
        if (dest == null)
        {
            return;
        }
        // set water camera to clear the same way as current camera
        dest.clearFlags = src.clearFlags;
        dest.backgroundColor = src.backgroundColor;
        if (src.clearFlags == CameraClearFlags.Skybox)
        {
            Skybox sky = src.GetComponent<Skybox>();
            Skybox mysky = dest.GetComponent<Skybox>();
            if (!sky || !sky.material)
            {
                mysky.enabled = false;
            }
            else
            {
                mysky.enabled = true;
                mysky.material = sky.material;
            }
        }
        // update other values to match current camera.
        // even if we are supplying custom camera&projection matrices,
        // some of values are used elsewhere (e.g. skybox uses far plane)
        dest.farClipPlane = src.farClipPlane;
        dest.nearClipPlane = src.nearClipPlane;
        dest.orthographic = src.orthographic;
        dest.fieldOfView = src.fieldOfView;
        dest.aspect = src.aspect;
        dest.orthographicSize = src.orthographicSize;
    }

    // Given position/normal of the plane, calculates plane in camera space.
    Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
    {
        Vector3 offsetPos = pos + normal * clipPlaneOffset;
        Matrix4x4 m = cam.worldToCameraMatrix;
        Vector3 cpos = m.MultiplyPoint(offsetPos);
        Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;
        return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
    }

    // Calculates reflection matrix around the given plane
    static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
    {
        reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
        reflectionMat.m01 = (-2F * plane[0] * plane[1]);
        reflectionMat.m02 = (-2F * plane[0] * plane[2]);
        reflectionMat.m03 = (-2F * plane[3] * plane[0]);

        reflectionMat.m10 = (-2F * plane[1] * plane[0]);
        reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
        reflectionMat.m12 = (-2F * plane[1] * plane[2]);
        reflectionMat.m13 = (-2F * plane[3] * plane[1]);

        reflectionMat.m20 = (-2F * plane[2] * plane[0]);
        reflectionMat.m21 = (-2F * plane[2] * plane[1]);
        reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
        reflectionMat.m23 = (-2F * plane[3] * plane[2]);

        reflectionMat.m30 = 0F;
        reflectionMat.m31 = 0F;
        reflectionMat.m32 = 0F;
        reflectionMat.m33 = 1F;
    }
}
