import React, { useEffect, useState } from 'react';
import { Layout, Table, Tag, Space, Button, Modal, Descriptions } from 'antd';
import Sidebar from '../../components/Sidebar';
import axiosPrivate from '../../api/axiosPrivate';
import { unwrapListResponse } from '../../api/responseHelper';
import MessageProvider from '../../components/MessageProvider';

const { Content } = Layout;

const SavedSearchesPage = () => {
  const [savedSearches, setSavedSearches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [detail, setDetail] = useState(null);
  const { showMessage, contextHolder } = MessageProvider();

  useEffect(() => {
    fetchSavedSearches();
  }, []);

  const fetchSavedSearches = async () => {
      try {
        const res = await axiosPrivate.get('/api/admin/saved-searches');
        const savedSearchesData = unwrapListResponse(res);
        setSavedSearches(savedSearchesData);
      } catch (error) {
        console.error('Error fetching saved searches:', error);
        const errorData = error.response?.data;
        const errorMessage = errorData?.message || errorData || 'Không thể tải danh sách khu vực tìm kiếm';
        showMessage.error(errorMessage);
      } finally {
        setLoading(false);
      }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Bạn có chắc chắn muốn xóa khu vực tìm kiếm này?')) {
      try {
        const response = await axiosPrivate.delete(`/api/saved-searches/${id}`);
        if (response.status === 200 || response.status === 204) {
          setSavedSearches(savedSearches => savedSearches.filter(ss => ss.id !== id));
          showMessage.success('Đã xóa khu vực tìm kiếm thành công');
        }
      } catch (error) {
        console.error('Error deleting saved search:', error);
        const errorMessage = error.response?.data?.message || error.response?.data || 'Không thể xóa khu vực tìm kiếm';
        showMessage.error(errorMessage);
      }
    }
  };

  const columns = [
    { 
      title: 'ID', 
      dataIndex: 'id', 
      key: 'id', 
      width: 80 
    },
    { 
      title: 'Người dùng', 
      dataIndex: 'userName', 
      key: 'userName',
      render: (text, record) => (
        <span style={{ color: '#fff' }}>
          {text || `User ID: ${record.userId}`}
        </span>
      )
    },
    { 
      title: 'Tọa độ', 
      key: 'coordinates',
      render: (_, record) => (
        <span style={{ color: '#fff' }}>
          {record.centerLatitude.toFixed(6)}, {record.centerLongitude.toFixed(6)}
        </span>
      )
    },
    { 
      title: 'Bán kính', 
      dataIndex: 'radiusKm', 
      key: 'radiusKm',
      render: (radius) => (
        <span style={{ color: '#fff' }}>{radius} km</span>
      )
    },
    { 
      title: 'Loại giao dịch', 
      dataIndex: 'transactionType', 
      key: 'transactionType',
      render: (type) => (
        <Tag color={type === 'Sale' ? 'green' : 'blue'}>{type}</Tag>
      )
    },
    { 
      title: 'Giá', 
      key: 'price',
      render: (_, record) => (
        <span style={{ color: '#fff' }}>
          {record.minPrice ? `${(record.minPrice / 1000000).toFixed(0)}M` : '0'} - {record.maxPrice ? `${(record.maxPrice / 1000000).toFixed(0)}M` : '∞'}
        </span>
      )
    },
    { 
      title: 'Thông báo', 
      dataIndex: 'enableNotification', 
      key: 'enableNotification',
      render: (enabled) => (
        <Tag color={enabled ? 'green' : 'default'}>
          {enabled ? 'Bật' : 'Tắt'}
        </Tag>
      )
    },
    { 
      title: 'Trạng thái', 
      dataIndex: 'isActive', 
      key: 'isActive',
      render: (active) => (
        <Tag color={active ? 'green' : 'red'}>
          {active ? 'Hoạt động' : 'Không hoạt động'}
        </Tag>
      )
    },
    { 
      title: 'Thời gian', 
      dataIndex: 'createdAt', 
      key: 'createdAt',
      render: (date) => (
        <span style={{ color: '#fff' }}>
          {date ? new Date(date).toLocaleString('vi-VN') : 'N/A'}
        </span>
      )
    },
    {
      title: 'Hành động',
      key: 'action',
      width: 120,
      render: (_, record) => (
        <Space>
          <Button onClick={() => setDetail(record)}>Xem</Button>
          <Button danger onClick={() => handleDelete(record.id)}>Xóa</Button>
        </Space>
      ),
    },
  ];

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {contextHolder}
      <Sidebar selectedKey="/admin/saved-searches" />
      <Layout>
        <Content style={{ margin: '24px 16px 0', background: '#141414' }}>
          <h1 style={{ color: '#fff', fontSize: 24, fontWeight: 700 }}>Quản lý khu vực tìm kiếm</h1>
          <Table 
            columns={columns} 
            dataSource={savedSearches} 
            loading={loading} 
            rowKey="id" 
            style={{ marginTop: 24 }}
            pagination={{ pageSize: 20 }}
          />
          <Modal 
            open={!!detail} 
            onCancel={() => setDetail(null)} 
            footer={null} 
            title="Chi tiết khu vực tìm kiếm"
            width={600}
          >
            {detail && (
              <Descriptions bordered column={1} size="small">
                <Descriptions.Item label="ID">{detail.id}</Descriptions.Item>
                <Descriptions.Item label="Người dùng">
                  {detail.userName || `User ID: ${detail.userId}`}
                </Descriptions.Item>
                <Descriptions.Item label="Vĩ độ">{detail.centerLatitude}</Descriptions.Item>
                <Descriptions.Item label="Kinh độ">{detail.centerLongitude}</Descriptions.Item>
                <Descriptions.Item label="Bán kính">{detail.radiusKm} km</Descriptions.Item>
                <Descriptions.Item label="Loại giao dịch">
                  <Tag color={detail.transactionType === 'Sale' ? 'green' : 'blue'}>
                    {detail.transactionType}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Giá tối thiểu">
                  {detail.minPrice ? `${(detail.minPrice / 1000000).toFixed(2)} triệu` : 'Không giới hạn'}
                </Descriptions.Item>
                <Descriptions.Item label="Giá tối đa">
                  {detail.maxPrice ? `${(detail.maxPrice / 1000000).toFixed(2)} triệu` : 'Không giới hạn'}
                </Descriptions.Item>
                <Descriptions.Item label="Bật thông báo">
                  <Tag color={detail.enableNotification ? 'green' : 'default'}>
                    {detail.enableNotification ? 'Có' : 'Không'}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Trạng thái">
                  <Tag color={detail.isActive ? 'green' : 'red'}>
                    {detail.isActive ? 'Hoạt động' : 'Không hoạt động'}
                  </Tag>
                </Descriptions.Item>
                <Descriptions.Item label="Thời gian tạo">
                  {detail.createdAt ? new Date(detail.createdAt).toLocaleString('vi-VN') : 'N/A'}
                </Descriptions.Item>
              </Descriptions>
            )}
          </Modal>
        </Content>
      </Layout>
    </Layout>
  );
};

export default SavedSearchesPage;

