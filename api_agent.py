import json
import urllib.request
import urllib.parse
import json
import websocket # pip install websocket-client
import uuid
import sys

# Địa chỉ API của ComfyUI (Localhost khi chạy trên Runpod)
SERVER_ADDRESS = "127.0.0.1:8188"
CLIENT_ID = str(uuid.uuid4())

def queue_prompt(prompt_workflow):
    """Gửi workflow JSON lên ComfyUI để xử lý"""
    p = {"prompt": prompt_workflow, "client_id": CLIENT_ID}
    data = json.dumps(p).encode('utf-8')
    req = urllib.request.Request(f"http://{SERVER_ADDRESS}/prompt", data=data)
    try:
        response = urllib.request.urlopen(req)
        return json.loads(response.read())
    except Exception as e:
        print(f"Lỗi kết nối tới ComfyUI ({SERVER_ADDRESS}): {e}")
        print("Vui lòng đảm bảo ComfyUI đang chạy.")
        sys.exit(1)

def get_history(prompt_id):
    """Lấy kết quả từ lịch sử"""
    with urllib.request.urlopen(f"http://{SERVER_ADDRESS}/history/{prompt_id}") as response:
        return json.loads(response.read())

def get_video(filename, subfolder, folder_type):
    """Tải video kết quả về máy"""
    data = {"filename": filename, "subfolder": subfolder, "type": folder_type}
    url_values = urllib.parse.urlencode(data)
    with urllib.request.urlopen(f"http://{SERVER_ADDRESS}/view?{url_values}") as response:
        return response.read()

def main():
    print("🎬 Khởi động Tự động hoá ComfyUI Video Pipeline...")
    
    # 1. Tải file JSON Workflow (Cần có file này từ giao diện ComfyUI Save API format)
    workflow_file = "workflows/vid2vid_workflow_api.json"
    
    try:
        with open(workflow_file, "r") as f:
            workflow = json.load(f)
    except FileNotFoundError:
        print(f"❌ Không tìm thấy file {workflow_file}.")
        print("💡 Hãy vào ComfyUI -> bật 'Enable Dev mode Options' -> Save (API Format) và lưu vào thư mục workflows.")
        sys.exit(1)

    # 2. Tuỳ chỉnh tự động (Ví dụ: Chèn prompt cho nhân vật Anna)
    # LƯU Ý: ID của node phụ thuộc vào workflow JSON thực tế của bạn. 
    # Ví dụ: Giả sử Node ID 6 là Text Prompt, Node ID 22 là Video Input
    custom_prompt = "(anna_woman:1.0), highly detailed, beautiful lighting, dancing in a futuristic cyberpunk city"
    
    # Tìm node CLIPTextEncode để sửa Prompt (bạn cần đổi ID cho đúng với JSON của bạn)
    # Ví dụ: workflow["6"]["inputs"]["text"] = custom_prompt
    
    print(f"Bắt đầu Generate với Prompt: {custom_prompt}")

    # 3. Kết nối WebSocket để theo dõi tiến độ
    ws = websocket.WebSocket()
    ws.connect(f"ws://{SERVER_ADDRESS}/ws?clientId={CLIENT_ID}")
    
    # 4. Gửi lệnh chạy
    prompt_res = queue_prompt(workflow)
    prompt_id = prompt_res['prompt_id']
    
    print("⏳ Đang xử lý trên RTX 4090... Vui lòng đợi.")
    
    # 5. Đợi quá trình hoàn tất
    while True:
        out = ws.recv()
        if isinstance(out, str):
            message = json.loads(out)
            if message['type'] == 'executing':
                data = message['data']
                if data['node'] is None and data['prompt_id'] == prompt_id:
                    print("✅ Xử lý hoàn tất!")
                    break
            elif message['type'] == 'progress':
                data = message['data']
                print(f"Tiến độ Node {data['node']}: {data['value']}/{data['max']}")
                
    # 6. Tải Video kết quả về
    history = get_history(prompt_id)[prompt_id]
    
    # Duyệt qua các node kết quả để tìm video
    for node_id in history['outputs']:
        node_output = history['outputs'][node_id]
        if 'gifs' in node_output: # Tùy thuộc vào Node Save Video (VHS)
            for video in node_output['gifs']:
                video_data = get_video(video['filename'], video['subfolder'], video['type'])
                out_path = f"output/{video['filename']}"
                with open(out_path, "wb") as f:
                    f.write(video_data)
                print(f"🎉 Đã lưu video thành công: {out_path}")

if __name__ == "__main__":
    main()
