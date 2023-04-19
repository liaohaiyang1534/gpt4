import os

import numpy as np
import matplotlib.pyplot as plt
from obspy import read
from scipy.optimize import curve_fit

from obspy.signal.trigger import classic_sta_lta, trigger_onset
from obspy.geodetics import locations2degrees

def linear_func(distance, velocity):
    return distance / velocity

def read_x_streams(full_paths):
    x_stream = []
    for path in full_paths:
        st = read(path)
        x_stream.append(st[0])
    return x_stream


def get_p_arrivals(streams, sta_length=1, lta_length=10, threshold_on=2, threshold_off=1):
    arrivals = []
    for st in streams:
        # 计算STA/LTA比例
        cft = classic_sta_lta(st.data, int(sta_length * st.stats.sampling_rate),
                              int(lta_length * st.stats.sampling_rate))
        
        # 检测到时
        on_off = trigger_onset(cft, threshold_on, threshold_off)
        
        # 如果检测到一个以上的到时，选择第一个
        if len(on_off) > 0:
            time_offset = on_off[0, 0] * st.stats.delta
            arrival = st.stats.starttime + time_offset
            arrivals.append(arrival)
        else:
            print(f"No P arrival found for trace {st.id}")
            arrivals.append(None)
    return arrivals


def calculate_distances(streams, ref_lat, ref_lon):
    distances = []
    for st in streams:
        lat = st.stats.sac.stla
        lon = st.stats.sac.stlo
        distance = locations2degrees(ref_lat, ref_lon, lat, lon)
        distances.append(distance)
    return distances



def plot_travel_time_curve(distances, arrivals):
    popt, pcov = curve_fit(linear_func, distances, arrivals)
    plt.scatter(distances, arrivals, label='Data')
    x = np.linspace(min(distances), max(distances), 100)  # 改为 100 个点
    y = linear_func(x, *popt)
    plt.plot(x, y, label=f'Fit: velocity={popt[0]:.2f}')
    plt.xlabel('Distance (deg)')
    plt.ylabel('Travel Time (s)')
    plt.legend()
    plt.show()




# def plot_travel_time_curve(distances, arrivals):
#     popt, pcov = curve_fit(linear_func, distances, arrivals)
#     plt.scatter(distances, arrivals, label='Data')
#     x = np.linspace(min(distances), max(distances), 100)
#     y = linear_func(x, *popt)
#     plt.plot(x, y, label=f'Fit: velocity={popt[0]:.2f}')
#     plt.xlabel('Distance (deg)')
#     plt.ylabel('Travel Time (s)')
#     plt.legend()
#     plt.show()

    
def get_files_with_extensions(directory, extensions):
    """
    Get all files with specific extensions in the given directory.

    Args:
        directory (str): The directory to search for files.
        extensions (list): A list of file extensions to search for.

    Returns:
        list: A list of file paths with the specified extensions.
    """
    result = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if any(file.endswith(ext) for ext in extensions):
                result.append(os.path.join(root, file))
                
    return result
    

def sort_files_by_component(files):
    """
    Sort the files by their component.

    Args:
        files (list): A list of file paths.

    Returns:
        dict: A dictionary with the components as keys and lists of corresponding files as values.
    """
    components = ['_E', '_N', '_Z', '_X']
    sorted_files = {component: [] for component in components}

    for file in files:
        for component in components:
            if component in file:
                sorted_files[component].append(file)
                break

    return sorted_files
    
    


full_paths = [
    r"C:\Users\haiyang\DAS_modeling\specfem3d_modeling\outputfiles_imaging\OUTPUT_FILES\DB.X01.FXX.sac",
    r"C:\Users\haiyang\DAS_modeling\specfem3d_modeling\outputfiles_imaging\OUTPUT_FILES\DB.X02.FXX.sac",
    r"C:\Users\haiyang\DAS_modeling\specfem3d_modeling\outputfiles_imaging\OUTPUT_FILES\DB.X03.FXX.sac",
]



print("Found files:")
for path in full_paths:
    print(path)


# 读取X分量文件并创建Stream对象
x_stream = read_x_streams(full_paths)

# 设定参考台站的经纬度
ref_lat, ref_lon = 40.0, 75.0

# 读取X分量地震记录并获取P波到时
arrivals = get_p_arrivals(x_stream)

# 计算台站距离
distances = calculate_distances(x_stream, ref_lat, ref_lon)

# 绘制走时曲线
if arrivals:
    plot_travel_time_curve(distances, arrivals) 
else:
    print("未找到到达时间。无法绘制走时曲线。")




输出结果：
Found files:
C:\Users\haiyang\DAS_modeling\specfem3d_modeling\outputfiles_imaging\OUTPUT_FILES\DB.X01.FXX.sac
C:\Users\haiyang\DAS_modeling\specfem3d_modeling\outputfiles_imaging\OUTPUT_FILES\DB.X02.FXX.sac
C:\Users\haiyang\DAS_modeling\specfem3d_modeling\outputfiles_imaging\OUTPUT_FILES\DB.X03.FXX.sac




