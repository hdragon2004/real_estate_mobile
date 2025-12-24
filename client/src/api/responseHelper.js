/**
 * Helper để unwrap response từ backend
 * Backend trả về format: { status, message, data }
 * Function này sẽ trả về data hoặc throw error nếu status không thành công
 */
export const unwrapResponse = (response) => {
  const responseData = response.data;
  
  // Kiểm tra nếu response có format mới { status, message, data }
  if (responseData && typeof responseData === 'object' && 'status' in responseData) {
    // Kiểm tra status code
    if (responseData.status >= 200 && responseData.status < 300) {
      // Trả về data nếu có, hoặc toàn bộ responseData nếu không có data field
      return responseData.data !== undefined ? responseData.data : responseData;
    } else {
      // Throw error nếu status không thành công
      const errorMessage = responseData.message || 'Có lỗi xảy ra';
      throw new Error(errorMessage);
    }
  }
  
  // Nếu không phải format mới, trả về response.data như cũ (backward compatible)
  return responseData;
};

/**
 * Helper để unwrap list response
 * Tương tự unwrapResponse nhưng đảm bảo trả về array
 */
export const unwrapListResponse = (response) => {
  const data = unwrapResponse(response);
  
  // Đảm bảo trả về array
  if (Array.isArray(data)) {
    return data;
  }
  
  // Nếu data là object có chứa array (ví dụ: { items: [...] })
  if (data && typeof data === 'object' && Array.isArray(data.items)) {
    return data.items;
  }
  
  // Nếu không phải array, trả về empty array
  return [];
};

